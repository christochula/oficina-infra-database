# oficina-infra-database

Banco de dados **PostgreSQL gerenciado (Amazon RDS)** da Oficina API, provisionado com **Terraform** e executado no **AWS Academy Learner Lab**.

Repositório 2 (de 4) do Tech Challenge Fase 3. Ordem de deploy: `oficina-infra-kubernetes` → **este** → `oficina-auth-serverless` → `oficina-api`.

## Descrição

- **Amazon RDS for PostgreSQL 16**, instância `db.t3.micro`, privada (`publicly_accessible = false`), storage `gp3` criptografado com a chave gerenciada `aws/rds`.
- **VPC default** do Learner Lab (a mesma do cluster EKS). Um security group libera a porta 5432 para o CIDR da VPC — pods do EKS e a Lambda de autenticação conectam direto ao endpoint do RDS.
- **Parameter group** com `rds.force_ssl=1`, `scram-sha-256` e logging (`log_connections`, `log_min_duration_statement`).
- **Senha gerada** (`random_password`) e gravada num **AWS Secrets Manager** secret (`oficina/homolog/database/connection`) com o JSON:
  ```json
  { "username","password","engine","host","port","dbname","sslmode","url" }
  ```
  onde `url` é a connection string Prisma (`...?schema=public&sslmode=require`).
- **Performance Insights** habilitado (retenção 7 dias, chave default). CloudWatch Logs export de `postgresql`.

### Diferenças em relação ao design corporativo (limitações do AWS Academy)

O Learner Lab bloqueia `iam:CreateRole`. Por isso foram removidos:

| Removido | Motivo | Alternativa |
| --- | --- | --- |
| RDS Proxy | precisa de IAM role própria | conexão direta ao RDS (`sslmode=require`) |
| Enhanced Monitoring | precisa de `monitoring_role_arn` | `monitoring_interval = 0` |
| KMS CMK | `kms:CreateKey` não confiável no lab | chave gerenciada `aws/rds` |
| SGs por referência entre stacks | acoplaria o `plan` ao estado do repo de EKS | ingress pelo CIDR da VPC |

## Tecnologias

Terraform 1.16 · AWS Provider 6.x · Amazon RDS PostgreSQL · AWS Secrets Manager · GitHub Actions.

## Execução local

```bash
terraform init \
  -backend-config="bucket=oficina-tc3-tfstate-$(aws sts get-caller-identity --query Account --output text)" \
  -backend-config="key=oficina/database/terraform.tfstate" \
  -backend-config="region=us-east-1"
terraform plan
terraform apply
```

Todos os IDs (VPC, subnets) são derivados da VPC default. Veja `variables.tf`.

## Deploy (CI/CD)

- `ci.yml` — em PR: `fmt` / `validate` / `plan`. Em push de branch: `validate`.
- `deploy.yml` — em push para `main` (+ manual): garante o bucket de state e roda `terraform apply`.

**GitHub Secrets** (renovar a cada sessão do Learner Lab): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`.

## Outputs (consumidos pelos outros repos)

| Output | Consumidor |
| --- | --- |
| `secret_name` / `secret_arn` | `oficina-api` (DATABASE_URL) e `oficina-auth-serverless` (consulta de cliente por CPF) |
| `db_endpoint` / `db_address` | referência operacional |
| `database_security_group_id` | referência |

## APIs

Não aplicável — repositório de infraestrutura. Swagger/Postman em `oficina-api`.

## Cleanup

```bash
terraform destroy
```

Destruir depois de `oficina-api` e `oficina-auth-serverless`. Sem deletion protection e com `skip_final_snapshot = true` (ambiente de lab).
