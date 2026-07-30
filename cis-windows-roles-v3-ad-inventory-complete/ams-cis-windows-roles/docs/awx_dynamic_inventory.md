# Integração com inventário dinâmico no AWX

Este playbook foi ajustado para trabalhar com um inventário único de Windows Servers. A separação entre `standalone`, `member_server` e `domain_controller` é feita em tempo de execução pela role `cis_detect_context`, usando a variável `ams_cis_profile`.

## Comportamento atual

| Tipo detectado | `ams_cis_profile` | Ação atual |
|---|---|---|
| Servidor fora de domínio | `standalone` | Aplica baseline CIS, incluindo password/lockout local |
| Servidor membro de domínio | `member_server` | Aplica baseline CIS, exceto password/lockout local |
| Domain Controller | `domain_controller` | Não aplica alterações neste momento |

## Inventário Active Directory filtrado

Foi incluído o script:

```text
inventory_sources/active_directory_windows.ps1
```

Objetivo do script:

- Consultar contas de computador no Active Directory.
- Trazer somente objetos habilitados.
- Trazer somente sistemas operacionais com `Windows Server`.
- Ignorar contas sem `DNSHostName`.
- Ignorar contas com `LastLogonDate` acima do limite configurado.
- Validar DNS, ping e portas de gerenciamento quando habilitado.
- Retornar JSON no formato de inventário dinâmico compatível com Ansible/AWX.

Critério padrão de elegibilidade:

```text
Enabled = true
OperatingSystem contém Windows Server
LastLogonDate dentro de 90 dias
DNSHostName preenchido
DNS resolve
Ping responde
Porta 5986, 5985 ou 22 disponível
```

Exemplos:

```powershell
.\active_directory_windows.ps1
.\active_directory_windows.ps1 -MaxInactiveDays 60
.\active_directory_windows.ps1 -SearchBase "OU=Servers,DC=empresa,DC=local"
.\active_directory_windows.ps1 -IncludeDomainControllers
.\active_directory_windows.ps1 -SkipPingValidation -SkipPortValidation
.\active_directory_windows.ps1 -PreferIPv4Address
```

Grupos retornados:

```text
windows_servers
windows_ad_filtered
windows_member_servers
windows_domain_controllers
windows_unreachable
```

Mesmo que Domain Controllers sejam incluídos com `-IncludeDomainControllers`, o playbook principal continua protegido por padrão:

```yaml
ams_skip_domain_controllers: true
ams_allow_domain_controller_changes: false
```

## Recomendação AMS

Use um inventário dinâmico único de Windows, alimentado por Azure, VMware, Active Directory e, quando disponível, CMDB/ServiceNow. O AD deve ser usado com filtros de elegibilidade para evitar contas de computador em desuso.
