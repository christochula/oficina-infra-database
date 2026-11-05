# oficina-infra-database

Infraestrutura PostgreSQL da Fase 3, preservada para historico e compatibilidade. Na Fase 4 cada servico provisiona e usa seus proprios dados e state Terraform em seu repositorio: OS e Billing usam bancos PostgreSQL independentes; Producao usa DynamoDB. Este banco legado nao e compartilhado pelos novos servicos e nao participa da Saga.

## Recursos existentes

RDS PostgreSQL 16, `db.t3.micro`, storage `gp3` criptografado, senha aleatoria no Secrets Manager e TLS obrigatorio (`rds.force_ssl=1`). O recurso foi mantido com os mesmos nomes/enderecos Terraform; nao ha remocao ou migracao de dados nesta alteracao. Acesso publico foi desabilitado (`publicly_accessible=false`) e ingress PostgreSQL restringido ao CIDR da VPC default. A Lambda de autenticacao consulta a API OS por HTTPS e nao recebe credenciais de banco.

A alteracao de rede sera efetivada apenas apos revisao do plan e execucao de deploy pelo usuario. Conexoes externas ao banco legado deixam de ser aceitas; operacoes administrativas devem partir de um workload autorizado na VPC. Cada servico da Fase 4 usa credencial/secret proprio e nao acessa bancos de outro servico. O isolamento logico nao depende apenas do CIDR de rede.

## Configuracao

Terraform 1.16, AWS Provider 6.x e credenciais Academy ativas. Entradas publicas estao em `variables.tf`; nenhum segredo deve ir para tfvars. O workflow usa GitHub Secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`. O bucket de state e `oficina-tc3-tfstate-REPLACE_ACCOUNT_ID`, key exclusiva `oficina/database/terraform.tfstate`, regiao `us-east-1`, criptografia e lockfile S3.

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

CI valida formato/configuracao e faz plan em PRs internos quando ha credenciais. Deploy verifica formato e configuracao antes do apply. Configurar protecao real de `main` com PR e checks `Validate` e `Plan`; um arquivo `.github/settings.yml` sozinho nao aplica protecao.

## Outputs e fronteiras

`db_endpoint`, `db_address`, `database_security_group_id`, `secret_name` e `secret_arn` referem-se apenas ao recurso legado. Nao configurar o auth com esses outputs. Os novos bancos/filas/Secrets de OS e Billing pertencem aos respectivos estados Terraform, e a tabela Producao pertence ao repositorio de Producao. O cluster e a unica plataforma compartilhada.

A Fase 4 usa seed demonstrativo em bancos novos; nao ha migracao do banco legado. Nao executar `destroy` como parte da preparacao da entrega. As definicoes existentes de lab (`skip_final_snapshot=true`, sem deletion protection) permanecem, sem uso nesta alteracao.
