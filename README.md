# terraform-create-vpc

Provisiona a VPC customizada da Sizebay com subnets públicas e privadas, NAT Gateway e Internet Gateway.

## Motivação

Os recursos eram provisionados na VPC default da AWS, que atribui IPs públicos às instâncias EC2 automaticamente. Essa VPC customizada resolve dois problemas:

- **Custo**: instâncias EC2 em subnets privadas não precisam de IPv4 público, eliminando a cobrança de ~$0.005/hora por IP
- **Segurança**: instâncias sem IP público não são acessíveis diretamente da internet; o acesso de saída é feito via NAT Gateway

## Arquitetura

```
VPC (10.0.0.0/16)
├── Subnet pública us-east-1a (10.1.0.0/24)  ← ALB + NAT Gateway
├── Subnet pública us-east-1b (10.1.1.0/24)  ← ALB
├── Subnet privada us-east-1a (10.1.2.0/24)  ← EC2 instances
└── Subnet privada us-east-1b (10.1.3.0/24)  ← EC2 instances

Internet Gateway → Route Table pública
NAT Gateway      → Route Table privada (saída para internet sem IP público)
```

As subnets são tagueadas com `Tier = "public"` e `Tier = "private"`, permitindo que os projetos descubram as subnets corretas via `data "aws_subnets"` sem precisar hardcodar IDs.

## Uso

```bash
# Staging
terraform init
terraform apply -var-file="env-staging.tfvars"

# Production
terraform init
terraform apply -var-file="env-production.tfvars"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws\_region | AWS region | string | `"us-east-1"` | no |
| environment | Environment identifier (e.g. staging, production) | string | n/a | yes |
| project | Project/company name for tagging and naming | string | n/a | yes |
| vpc\_cidr | CIDR block for the VPC | string | `"10.1.0.0/16"` | no |
| public\_subnet\_cidrs | CIDRs for public subnets, one per AZ | list(string) | n/a | yes |
| private\_subnet\_cidrs | CIDRs for private subnets, one per AZ | list(string) | n/a | yes |
| availability\_zones | Availability zones (must match number of CIDRs) | list(string) | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc\_id | ID da VPC criada |
| vpc\_cidr | CIDR da VPC |
| public\_subnet\_ids | IDs das subnets públicas |
| private\_subnet\_ids | IDs das subnets privadas |
| nat\_gateway\_id | ID do NAT Gateway |
| nat\_gateway\_public\_ip | IP público do NAT Gateway |

## Após provisionar

Copie o `vpc_id` do output e atualize o `aws_vpc_id` no `env-staging.tfvars` dos projetos que usam o módulo `terraform-ha-ec2-shared`.
