# KatanaPay Platform - Day 1 Infrastructure

Безопасная платформа AWS + Kubernetes для микросервиса платежей с учётом требований PCI DSS.

## Структура проекта

```
├── main.tf                    # Root module
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs  
├── versions.tf                # Provider versions
├── terraform.tfvars.example   # Example configuration
├── modules/
│   ├── vpc/                   # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/              # Security module (KMS, Security Groups)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                   # EKS module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                   # IAM module (IRSA roles)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── irsa/                  # Reusable IRSA module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   └── additional-irsa-role.tf # Example of creating custom IRSA roles
├── README.md
└── SUBMISSION.md
```

## Архитектура высокого уровня

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Account                            │
├─────────────────────────────────────────────────────────────────┤
│ VPC (10.0.0.0/16)                                               │
│                                                                 │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐     │
│ │  Public Subnets │ │ Private Subnets │ │Isolated Subnets │     │
│ │                 │ │                 │ │                 │     │
│ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │     │
│ │ │Internet     │ │ │ │ EKS Cluster │ │ │ │   PCI Zone  │ │     │
│ │ │Gateway      │ │ │ │             │ │ │ │             │ │     │
│ │ └─────────────┘ │ │ │ ┌─────────┐ │ │ │ │  (Future:   │ │     │
│ │ ┌─────────────┐ │ │ │ │Control  │ │ │ │ │   Vault)    │ │     │
│ │ │NAT Gateway  │ │ │ │ │Plane    │ │ │ │ └─────────────┘ │     │
│ │ └─────────────┘ │ │ │ └─────────┘ │ │ └─────────────────┘     │
│ └─────────────────┘ │ │             │ │                         │
│                     │ │ ┌─────────┐ │ │                         │
│                     │ │ │Node 1   │ │ │                         │
│                     │ │ │Node 2   │ │ │                         │
│                     │ │ └─────────┘ │ │                         │
│                     │ └─────────────┘ │                         │
│                     └─────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘

Security Services:
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│     KMS     │ │  IAM+IRSA   │ │   Secrets   │ │ CloudWatch  │
│   Keys      │ │   Roles     │ │  Manager    │ │    Logs     │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘

Application Layer:
┌─────────────────────────────────────────────────────────────────┐
│                     Payment Microservice                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │Payment Pod 1│    │Payment Pod 2│    │Logging      │          │
│  │+ Sidecar    │    │+ Sidecar    │    │Sidecar      │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
│                                                                 │
│  OIDC Provider ←→ IAM Roles ←→ Service Accounts                 │
└─────────────────────────────────────────────────────────────────┘

Network Flow:
Internet → IGW → NAT → Worker Nodes → Payment Pods
Payment Pods → Secrets Manager (via IRSA)
Payment Pods → CloudWatch Logs
EKS Control Plane → KMS (secrets encryption)
```

## Модульная архитектура

### VPC Module (`modules/vpc/`)
- Multi-AZ VPC с public, private и isolated подсетями
- NAT Gateway для outbound connectivity
- VPC Flow Logs для security monitoring
- Network segmentation для PCI compliance

### Security Module (`modules/security/`)
- KMS ключи для шифрования EKS secrets
- Security Groups для cluster и nodes
- CloudWatch Log Groups с encryption
- Базовые security policies

### EKS Module (`modules/eks/`)
- Приватный EKS cluster (control plane недоступен из интернета)
- Managed Node Groups с encrypted EBS
- IRSA (IAM Roles for Service Accounts)
- EKS addons: CoreDNS, VPC-CNI, EBS CSI Driver

### IAM Module (`modules/iam/`)
- IRSA роли для payment service
- Least privilege policies
- EBS CSI driver role
- Cluster autoscaler role (future)

## Принципы безопасности Zero Trust

### 1. Network Segmentation
- **Private EKS cluster** - control plane недоступен из интернета
- **Изолированные подсети** для PCI workloads
- **VPC Flow Logs** для аудита сетевого трафика

## OIDC Provider и IRSA

### Что такое IRSA?
IRSA (IAM Roles for Service Accounts) позволяет Kubernetes pod'ам использовать IAM роли AWS без необходимости хранить долгосрочные ключи доступа.

### Как это работает:
1. **OIDC Provider** - создается для EKS кластера и регистрируется в AWS IAM
2. **Service Account** - в Kubernetes с аннотацией `eks.amazonaws.com/role-arn`
3. **IAM Role** - с trust policy, позволяющим конкретному service account его использовать
4. **Pod** - автоматически получает AWS credentials через STS AssumeRoleWithWebIdentity

### Создание дополнительных IRSA ролей:

```hcl
module "my_service_irsa" {
  source = "./modules/irsa"

  role_name = "my-service-role"
  
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url

  service_accounts = [
    {
      namespace = "my-app"
      name      = "my-service"
    }
  ]

  policy_statements = [
    {
      sid    = "AllowS3Access"
      effect = "Allow"
      actions = ["s3:GetObject"]
      resources = ["arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

### Готовые IRSA роли:
- **payment-service** - доступ к Secrets Manager и CloudWatch
- **ebs-csi-driver** - управление EBS volumes
- **cluster-autoscaler** - автоскейлинг node groups
- **aws-load-balancer-controller** - управление ALB/NLB
- **external-dns** - управление Route53 записями
- **external-secrets** - синхронизация секретов из AWS

### 3. Data Protection
- **EKS secrets encryption** с помощью AWS KMS
- **Encrypted EBS volumes** для persistent storage
- **TLS в transit** для всех коммуникаций

## Первые три шага автоматизации безопасности

### 1. Pod Security Standards (ПРИОРИТЕТ 1)
**Что:** Включить Pod Security Standards на уровне namespace
**Почему первое:** Предотвращает запуск privileged контейнеров и основные векторы атак на runtime

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: payment
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 2. Network Policies (ПРИОРИТЕТ 2) 
**Что:** Реализовать default-deny network policies для изоляции трафика
**Почему второе:** Ограничивает lateral movement при компрометации pod'а

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-netpol
  namespace: payment
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 3. Admission Controllers (ПРИОРИТЕТ 3)
**Что:** Настроить OPA Gatekeeper или Kyverno для policy enforcement
**Почему третье:** Автоматизирует compliance проверки на уровне API server

Примеры политик:
- Запрет privileged контейнеров
- Обязательные resource limits
- Проверка подписи образов

## Использование модулей

### 1. Клонирование и настройка
```bash
git clone <repository>
cd katana-pay-platform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Редактирование конфигурации
```bash
vim terraform.tfvars
```

### 3. Инициализация и деплой
```bash
terraform init
terraform plan
terraform apply
```

### 4. Подключение к кластеру
```bash
aws eks update-kubeconfig --name katana-pay-dev-eks --region us-west-2
```

## Соответствие PCI DSS зонированию

### Зоны безопасности

**CDE (Cardholder Data Environment):**
- Isolated subnets (10.0.201.0/24-203.0/24)
- Будущее расположение Vault для токенизации
- Ограниченный доступ только для авторизованного персонала

**DMZ (Demilitarized Zone):**
- Private subnets с EKS nodes
- Payment microservice с минимальными привилегиями
- Логирование всех операций

**Internal Network:**
- Management и мониторинг компоненты
- Централизованное логирование (CloudWatch)

### Контроли доступа (Требование 7)
- IRSA для granular permissions
- Service accounts с ограниченными ролями
- Network policies для микросегментации

### Управление секретами (Требование 8)
- AWS Secrets Manager для API ключей
- KMS encryption для secrets at rest
- Ротация секретов через автоматизацию

### Audit логирование (Требование 10)
- EKS audit logs в CloudWatch
- VPC Flow Logs для сетевого мониторинга
- Application logs через sidecar pattern

## Следующие шаги (Sprint 2)

### Vault интеграция
- Развертывание HashiCorp Vault в isolated subnets
- Настройка auto-unsealing с AWS KMS
- Динамические секреты для database доступа

### GitOps с ArgoCD
- Автоматизация деплоя через Git workflows
- Policy-as-Code с помощью Conftest
- Sealed Secrets для безопасного хранения в Git

### Мониторинг и алертинг
- Prometheus + Grafana stack
- Falco для runtime security мониторинга
- PCI compliance дашборды

## Принципы безопасности Zero Trust

### 1. Network Segmentation
- **Private EKS cluster** - control plane недоступен из интернета
- **Изолированные подсети** для PCI workloads
- **VPC Flow Logs** для аудита сетевого трафика

### 2. Identity & Access Management  
- **IRSA (IAM Roles for Service Accounts)** вместо долгосрочных ключей
- **Принцип минимальных привилегий** для каждого компонента
- **Pod-level security contexts** с non-root пользователями

### 3. Data Protection
- **EKS secrets encryption** с помощью AWS KMS
- **Encrypted EBS volumes** для persistent storage
- **TLS в transit** для всех коммуникаций

## Первые три шага автоматизации безопасности

### 1. Pod Security Standards (ПРИОРИТЕТ 1)
**Что:** Включить Pod Security Standards на уровне namespace
**Почему первое:** Предотвращает запуск privileged контейнеров и основные векторы атак на runtime

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: payment
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### 2. Network Policies (ПРИОРИТЕТ 2) 
**Что:** Реализовать default-deny network policies для изоляции трафика
**Почему второе:** Ограничивает lateral movement при компрометации pod'а

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-netpol
  namespace: payment
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 3. Admission Controllers (ПРИОРИТЕТ 3)
**Что:** Настроить OPA Gatekeeper или Kyverno для policy enforcement
**Почему третье:** Автоматизирует compliance проверки на уровне API server

Примеры политик:
- Запрет privileged контейнеров
- Обязательные resource limits
- Проверка подписи образов

## Соответствие PCI DSS зонированию

### Зоны безопасности

**CDE (Cardholder Data Environment):**
- Isolated subnets (10.0.201.0/24-203.0/24)
- Будущее расположение Vault для токенизации
- Ограниченный доступ только для авторизованного персонала

**DMZ (Demilitarized Zone):**
- Private subnets с EKS nodes
- Payment microservice с минимальными привилегиями
- Логирование всех операций

**Internal Network:**
- Management и мониторинг компоненты
- Централизованное логирование (CloudWatch)

### Контроли доступа (Требование 7)
- IRSA для granular permissions
- Service accounts с ограниченными ролями
- Network policies для микросегментации

### Управление секретами (Требование 8)
- AWS Secrets Manager для API ключей
- KMS encryption для secrets at rest
- Ротация секретов через автоматизацию

### Audit логирование (Требование 10)
- EKS audit logs в CloudWatch
- VPC Flow Logs для сетевого мониторинга
- Application logs через sidecar pattern

## Следующие шаги (Sprint 2)

### Vault интеграция
- Развертывание HashiCorp Vault в isolated subnets
- Настройка auto-unsealing с AWS KMS
- Динамические секреты для database доступа

### GitOps с ArgoCD
- Автоматизация деплоя через Git workflows
- Policy-as-Code с помощью Conftest
- Sealed Secrets для безопасного хранения в Git

### Мониторинг и алертинг
- Prometheus + Grafana stack
- Falco для runtime security мониторинга
- PCI compliance дашборды