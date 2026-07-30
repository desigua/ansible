# AMS CIS L1 Core - Windows Server Modular DC Safe

Pacote modular de hardening CIS L1 para Windows Server, preparado para execução via AWX/Ansible com um inventário único de Windows.

## Atualizações desta versão

- Adicionada variável consolidada `ams_cis_profile`.
- Domain Controllers são detectados automaticamente e ignorados antes de qualquer alteração.
- Adicionadas variáveis:

```yaml
ams_skip_domain_controllers: true
ams_allow_domain_controller_changes: false
```

## Perfis detectados

```text
standalone
member_server
domain_controller
```

## Estrutura

```text
site.yml
rollback.yml
group_vars/windows_servers.yml
docs/awx_dynamic_inventory.md
inventory_sources/
roles/
```

## Controles incluídos para standalone/member server

- Password Policy para servidores standalone
- Account Lockout para servidores standalone
- Audit Policy avançada
- Windows Firewall
- Microsoft Defender
- Defender ASR Rules
- PowerShell Module Logging
- PowerShell Script Block Logging
- PowerShell Transcription com diretório definido
- NTLM Restriction
- LLMNR Disable
- NetBIOS Disable quando aplicável
- Anonymous SID Enumeration Block
- Guest Account Disable
- Remote Registry Disable
- Autorun Disable
- UAC Hardening
- TLS 1.0 e TLS 1.1 Disable
- Event Log Size
- SMBv1 Disable
- LAN Manager Authentication Level
- Cached Logons
- SMB Signing
- Credential Guard
- Windows Event Forwarding Service
- BitLocker Validation
- RDP Hardening
- WinRM Hardening
- Local Administrators Compliance
- Service Account Compliance
- NTP Compliance
- Time Zone Compliance
- Evidências pós-execução
- Backup inicial para rollback básico

## Importante sobre Domain Controllers

Nenhuma alteração é aplicada em Domain Controllers neste momento. O playbook executa apenas a detecção de contexto e encerra o host com `meta: end_host`.

LDAP Signing para DCs foi deixado comentado/inibido em `roles/cis_network_hardening/tasks/main.yml`.

## Como executar

```bash
ansible-playbook -i inventory.ini site.yml --limit windows_servers
```

Rollback básico:

```bash
ansible-playbook -i inventory.ini rollback.yml --limit windows_servers
```

## AWX

Consulte:

```text
docs/awx_dynamic_inventory.md
```
