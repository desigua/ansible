# AMS CIS L1 Core - Windows Server Modular

Este pacote modulariza o playbook de hardening Windows Server em roles separadas para uso em AWX/Ansible.

## Estrutura

```text
site.yml
rollback.yml
group_vars/windows_servers.yml
roles/
  cis_detect_context/
  cis_evidence/
  cis_password_lockout/
  cis_audit_policy/
  cis_firewall_defender/
  cis_powershell_logging/
  cis_network_hardening/
  cis_system_hardening/
  cis_remote_access/
  cis_compliance_validation/
```

## Controles incluídos

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
- LDAP Signing para Domain Controllers
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

## Como executar

Exemplo:

```bash
ansible-playbook -i inventory.ini site.yml --limit windows_servers
```

Por tag:

```bash
ansible-playbook -i inventory.ini site.yml --tags "network_hardening,ntlm,smb,tls"
```

Rollback básico:

```bash
ansible-playbook -i inventory.ini rollback.yml --limit windows_servers
```

## Observações importantes

- Password Policy e Account Lockout são aplicadas somente quando o servidor não é membro de domínio.
- LDAP Signing foi limitado por padrão a Domain Controllers.
- TLS 1.0/1.1, Credential Guard, SMB Signing, NTLM restriction e WinRM hardening podem impactar aplicações legadas.
- Tamper Protection geralmente é gerenciado via Microsoft Defender for Endpoint/Intune/GPO, portanto o playbook valida e registra evidência.
- O rollback incluído é básico e restaura a política local via `secedit`. Para rollback completo, recomenda-se uma role dedicada por controle.
