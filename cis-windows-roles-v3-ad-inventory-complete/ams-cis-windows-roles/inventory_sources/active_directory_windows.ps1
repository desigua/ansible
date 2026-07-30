<#
.SYNOPSIS
  Inventário dinâmico Active Directory para AWX/Ansible filtrando somente Windows Servers ativos.
.DESCRIPTION
  Retorna JSON compatível com inventário dinâmico do Ansible/AWX.
  Filtra contas habilitadas, Windows Server, LastLogonDate recente, DNSHostName, DNS, ping e portas de gerenciamento.
#>
[CmdletBinding()]
param(
    [string]$SearchBase = "",
    [int]$MaxInactiveDays = 90,
    [switch]$SkipDnsValidation,
    [switch]$SkipPingValidation,
    [switch]$SkipPortValidation,
    [int[]]$ManagementPorts = @(5986, 5985, 22),
    [switch]$PreferIPv4Address,
    [switch]$IncludeDomainControllers,
    [string[]]$ExcludeNamePatterns = @("*-OLD*","*-OBS*","*-OBSOLETO*","*-DECOM*","*-DISABLED*","*-DESATIVADO*")
)
function New-InventoryObject {
    [ordered]@{
        windows_servers = [ordered]@{ hosts = @() }
        windows_ad_filtered = [ordered]@{ hosts = @() }
        windows_member_servers = [ordered]@{ hosts = @() }
        windows_domain_controllers = [ordered]@{ hosts = @() }
        windows_unreachable = [ordered]@{ hosts = @() }
        _meta = [ordered]@{ hostvars = [ordered]@{} }
    }
}
function Test-PortOpen {
    param([string]$ComputerName,[int[]]$Ports)
    foreach ($Port in $Ports) {
        try {
            if (Test-NetConnection -ComputerName $ComputerName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue) {
                return [ordered]@{ Reachable = $true; Port = $Port }
            }
        } catch {}
    }
    return [ordered]@{ Reachable = $false; Port = $null }
}
function Test-ExcludedName {
    param([string]$Name,[string[]]$Patterns)
    foreach ($Pattern in $Patterns) { if ($Name -like $Pattern) { return $true } }
    return $false
}
try { Import-Module ActiveDirectory -ErrorAction Stop } catch {
    ([ordered]@{ windows_servers=[ordered]@{hosts=@()}; _meta=[ordered]@{hostvars=[ordered]@{}}; error="ActiveDirectory module not available: $($_.Exception.Message)" }) | ConvertTo-Json -Depth 20
    exit 1
}
$CutOffDate = (Get-Date).AddDays(-1 * $MaxInactiveDays)
$Inventory = New-InventoryObject
$Properties = @('DNSHostName','OperatingSystem','OperatingSystemVersion','LastLogonDate','IPv4Address','Enabled','DistinguishedName','PrimaryGroupID','whenCreated','whenChanged','Description')
$Filter = 'Enabled -eq $true -and OperatingSystem -like "*Windows Server*"'
try {
    if ([string]::IsNullOrWhiteSpace($SearchBase)) { $Servers = Get-ADComputer -Filter $Filter -Properties $Properties }
    else { $Servers = Get-ADComputer -SearchBase $SearchBase -Filter $Filter -Properties $Properties }
} catch {
    $Inventory['error'] = "AD query failed: $($_.Exception.Message)"
    $Inventory | ConvertTo-Json -Depth 20
    exit 1
}
foreach ($Server in $Servers) {
    if (Test-ExcludedName -Name $Server.Name -Patterns $ExcludeNamePatterns) { continue }
    if ([string]::IsNullOrWhiteSpace($Server.DNSHostName)) { continue }
    if ($null -eq $Server.LastLogonDate -or $Server.LastLogonDate -lt $CutOffDate) { continue }
    $IsDomainController = ($Server.PrimaryGroupID -eq 516)
    if ($IsDomainController -and -not $IncludeDomainControllers) { continue }
    $HostName = $Server.DNSHostName.ToLower()
    $AnsibleHost = $HostName
    $DnsResolved = $null; $PingOnline = $null; $MgmtReachable = $null; $MgmtPort = $null
    if (-not $SkipDnsValidation) {
        try {
            $DnsResult = Resolve-DnsName -Name $HostName -ErrorAction Stop | Where-Object { $_.IPAddress } | Select-Object -First 1
            if ($null -eq $DnsResult) { continue }
            $DnsResolved = $true
            if ($PreferIPv4Address -and $DnsResult.IPAddress) { $AnsibleHost = $DnsResult.IPAddress }
        } catch { continue }
    }
    if (-not $SkipPingValidation) {
        try { $PingOnline = Test-Connection -ComputerName $HostName -Count 1 -Quiet -ErrorAction SilentlyContinue; if (-not $PingOnline) { continue } } catch { continue }
    }
    if (-not $SkipPortValidation) {
        $PortResult = Test-PortOpen -ComputerName $HostName -Ports $ManagementPorts
        $MgmtReachable = [bool]$PortResult.Reachable; $MgmtPort = $PortResult.Port
        if (-not $MgmtReachable) { $Inventory.windows_unreachable.hosts += $HostName; continue }
    }
    $Inventory.windows_servers.hosts += $HostName
    $Inventory.windows_ad_filtered.hosts += $HostName
    if ($IsDomainController) { $Inventory.windows_domain_controllers.hosts += $HostName } else { $Inventory.windows_member_servers.hosts += $HostName }
    $Inventory._meta.hostvars[$HostName] = [ordered]@{
        ansible_host=$AnsibleHost; computer_name=$Server.Name; dns_name=$Server.DNSHostName; operating_system=$Server.OperatingSystem; operating_system_version=$Server.OperatingSystemVersion
        last_logon_date=if ($Server.LastLogonDate) { $Server.LastLogonDate.ToString('s') } else { $null }
        enabled=$Server.Enabled; distinguished_name=$Server.DistinguishedName; primary_group_id=$Server.PrimaryGroupID; is_domain_controller=$IsDomainController
        inventory_source='ActiveDirectory'; inventory_filter='enabled_windows_server_recent_logon_dns_connectivity'; max_inactive_days=$MaxInactiveDays
        dns_resolved=$DnsResolved; ping_online=$PingOnline; management_reachable=$MgmtReachable; management_port=$MgmtPort
        when_created=if ($Server.whenCreated) { $Server.whenCreated.ToString('s') } else { $null }
        when_changed=if ($Server.whenChanged) { $Server.whenChanged.ToString('s') } else { $null }
        description=$Server.Description
    }
}
foreach ($GroupName in @('windows_servers','windows_ad_filtered','windows_member_servers','windows_domain_controllers','windows_unreachable')) { $Inventory[$GroupName].hosts = @($Inventory[$GroupName].hosts | Select-Object -Unique) }
$Inventory | ConvertTo-Json -Depth 20
