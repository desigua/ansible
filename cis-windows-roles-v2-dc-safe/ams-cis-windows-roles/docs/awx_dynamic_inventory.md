# Integração com inventário dinâmico no AWX

Este playbook foi ajustado para trabalhar com um inventário único de Windows Servers. A separação entre `standalone`, `member_server` e `domain_controller` é feita em tempo de execução pela role `cis_detect_context`, usando a variável consolidada `ams_cis_profile`.

## Comportamento atual

| Tipo detectado | `ams_cis_profile` | Ação atual |
|---|---|---|
| Servidor fora de domínio | `standalone` | Aplica baseline CIS, incluindo password/lockout local |
| Servidor membro de domínio | `member_server` | Aplica baseline CIS, exceto password/lockout local |
| Domain Controller | `domain_controller` | Não aplica alterações neste momento |

Por padrão:

```yaml
ams_skip_domain_controllers: true
ams_allow_domain_controller_changes: false
```

## Modelo recomendado no AWX

Use um único Inventory no AWX, por exemplo:

```text
Inventory: Windows-Servers-Dynamic
```

Esse inventário pode ser alimentado por uma ou mais fontes dinâmicas:

- VMware/vCenter
- Azure
- CMDB/ServiceNow
- Script customizado consultando Active Directory

O importante é que todos os Windows Servers entrem no mesmo inventário lógico. O playbook identifica o perfil durante a execução.

## Passos no AWX

1. Acesse **Resources > Inventories**.
2. Crie ou selecione o inventário **Windows-Servers-Dynamic**.
3. Em **Sources**, adicione uma fonte dinâmica, como VMware, Azure ou SCM inventory source.
4. Configure a credencial da fonte, por exemplo vCenter, Azure ou Git/SCM.
5. Configure filtros para retornar apenas servidores Windows quando possível.
6. Ative sincronização periódica se aplicável.
7. Em **Projects**, crie um projeto apontando para o repositório Git do pacote `ams-cis-windows-roles`.
8. Em **Templates**, crie um Job Template usando:

```text
Playbook: site.yml
Inventory: Windows-Servers-Dynamic
Credentials: credencial Windows/AD/SSH/WinRM conforme arquitetura AMS
```

## Proteção de Domain Controllers

Domain Controllers são detectados, mas encerrados com `meta: end_host` antes das roles de alteração.

Isso evita aplicar automaticamente controles sensíveis como:

- LDAP Signing
- TLS Hardening
- Credential Guard
- SMB Signing
- RDP Hardening
- WinRM Hardening
- Defender/ASR
- Políticas locais

Para DCs, crie futuramente uma baseline separada, exemplo:

```text
cis_domain_controller_baseline
```

com validação, homologação e janela dedicada.
