# AMS CIS L1 Core - Windows Server Modular DC Safe

Pacote modular de hardening CIS L1 para Windows Server, preparado para execução via AWX/Ansible com inventário único de Windows.

## Atualizações

- `ams_cis_profile`: `standalone`, `member_server` ou `domain_controller`.
- Domain Controllers são detectados e ignorados antes de qualquer alteração.
- Incluído inventário Active Directory filtrado.

## Inventários incluídos

```text
inventory_sources/azure_rm_windows.yml.example
inventory_sources/vmware_windows.yml.example
inventory_sources/active_directory_windows.ps1
inventory_sources/active_directory_windows.yml.example
```

## Inventário Active Directory filtrado

O arquivo `inventory_sources/active_directory_windows.ps1` traz somente Windows Servers elegíveis:

- `Enabled = true`
- `OperatingSystem` contendo `Windows Server`
- `LastLogonDate` recente, padrão 90 dias
- `DNSHostName` preenchido
- DNS válido
- Ping opcional
- Porta de gerenciamento opcional: 5986, 5985 ou 22
- Exclusão por padrões de nome como `OLD`, `OBSOLETO`, `DECOM`, `DISABLED`, `DESATIVADO`

## Execução

```bash
ansible-playbook -i inventory.ini site.yml --limit windows_servers
```

Rollback básico:

```bash
ansible-playbook -i inventory.ini rollback.yml --limit windows_servers
```

Documentação AWX:

```text
docs/awx_dynamic_inventory.md
```
