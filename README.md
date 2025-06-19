# KatanaPay Platform

> Secure, PCI DSS compliant payment platform built on AWS EKS with Zero-Trust architecture

## 📋 Обзор проекта

KatanaPay - это современная платежная платформа, построенная с применением принципов Zero-Trust security и соответствующая требованиям PCI DSS Level 1. Платформа использует Kubernetes, HashiCorp Vault, и полный стек AWS сервисов для обеспечения максимальной безопасности и масштабируемости.

### Ключевые особенности

- ✅ **Zero-Trust Security** - "Never trust, always verify"
- ✅ **PCI DSS Level 1** - полное соответствие требованиям
- ✅ **Kubernetes-native** - cloud-native архитектура
- ✅ **GitOps** - декларативное управление инфраструктурой
- ✅ **Observability** - полный мониторинг и логирование
- ✅ **Multi-environment** - dev/stage/prod окружения

## 🏗️ Структура репозитория

```
katanapay-platform/
├── 📊 diagrams/                     # Архитектурные диаграммы
├── ☸️  kubernetes/                  # Kubernetes manifests и Helm charts
└── 🏗️  terraform/                   # Infrastructure as Code
```

### 📊 `/diagrams` - Архитектурные диаграммы

Содержит визуальные схемы архитектуры в формате Mermaid:

```
diagrams/
├── README.md                        # Описание всех диаграмм
├── zero-trust-architecture          # Общая архитектура Zero-Trust
├── zero-trust-requests-flow         # Пошаговый flow обработки запросов
└── threat-model-security-controls   # Модель угроз и контроли безопасности
```

### ☸️ `/kubernetes` - Kubernetes Resources

Helm-based deployment с поддержкой multiple environments:

```
kubernetes/
├── charts/katanapay/               # Основной Helm chart
│   ├── Chart.yaml                  # Метаданные chart'а
│   ├── templates/                  # Kubernetes templates
│   └── values.yaml                 # Дефолтные значения
├── envs/                          # Environment-specific конфигурации
│   ├── default/                   # Базовые настройки
│   ├── dev/                       # Development окружение
│   ├── stage/                     # Staging окружение
│   └── prod/                      # Production окружение
├── helmfile.yaml                  # Helmfile конфигурация
└── releases/katanapay.yaml        # Release определения
```

**Что найдете:**
- Payment microservice deployments
- Security policies (PSS, Network Policies)
- Service mesh configuration (Istio)
- Monitoring stack (Prometheus, Grafana)
- Logging infrastructure (Loki, Fluent Bit)
- External Secrets Operator config
- Vault integration manifests

### 🏗️ `/terraform` - Infrastructure as Code

Модульная Terraform архитектура для AWS:

```
terraform/
├── modules/                       # Переиспользуемые модули
│   ├── vpc/                      # VPC с network segmentation
│   ├── eks/                      # EKS cluster с security hardening
│   ├── security/                 # KMS, Security Groups, CloudWatch
│   ├── iam/                      # IAM roles для различных сервисов
│   └── irsa/                     # Переиспользуемый IRSA модуль
├── *.tf                          # Root модуль конфигурации
├── outputs.tf                    # Выходные значения
└── README.md                     # Инструкции по развертыванию
```

**Что найдете:**
- VPC с public/private/isolated/database подсетями
- EKS cluster с приватным control plane
- IRSA setup для безопасного доступа к AWS
- HashiCorp Vault в isolated подсетях
- KMS ключи для шифрования
- Security Groups с принципом least privilege
- CloudWatch для централизованного логирования

## 🚀 Быстрый старт

### Предварительные требования

- [Terraform](https://www.terraform.io/) >= 1.7
- [AWS CLI](https://aws.amazon.com/cli/) v2 configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/) >= 3.0
- [Helmfile](https://helmfile.readthedocs.io/)

### 1. Развертывание инфраструктуры

```bash
# Переход в terraform директорию
cd terraform/

# Инициализация и планирование
terraform init
terraform plan -var="environment=dev"

# Развертывание
terraform apply -var="environment=dev"

# Получение kubeconfig
aws eks update-kubeconfig --name katana-pay-dev-eks --region us-west-2
```

### 2. Развертывание приложений

```bash
# Переход в kubernetes директорию
cd kubernetes/

# Развертывание в dev окружение
helmfile -e dev apply

# Проверка статуса
kubectl get pods -A
```

### 3. Проверка работоспособности

```bash
# Проверка EKS кластера
kubectl cluster-info

# Проверка security policies
kubectl get psp,networkpolicies -A

# Проверка Vault
kubectl get pods -n vault

# Проверка мониторинга
kubectl get pods -n monitoring
```

## 🔐 Security Features

### Zero-Trust Architecture
- **Network Segmentation**: VPC с изолированными подсетями
- **Micro-segmentation**: Kubernetes Network Policies
- **Identity-based Access**: IRSA для всех компонентов
- **mTLS Everywhere**: Istio Service Mesh
- **Continuous Verification**: Runtime security с Falco

### PCI DSS Compliance
- **Requirement 1-2**: Network security и firewall
- **Requirement 3-4**: Data protection и encryption
- **Requirement 7-8**: Access control и identity management
- **Requirement 10**: Logging и monitoring
- **Requirement 11**: Security testing

### Secret Management
- **HashiCorp Vault**: Centralized secret storage
- **Dynamic Secrets**: Short-lived database credentials
- **IRSA Integration**: AWS services access без long-term keys
- **External Secrets Operator**: Kubernetes secret synchronization

## 📊 Monitoring & Observability

### Metrics
- **Prometheus**: Metrics collection
- **Grafana**: Visualization и dashboards
- **AlertManager**: Incident management

### Logging
- **Loki**: Log aggregation
- **Fluent Bit**: Log collection и shipping
- **CloudWatch**: Centralized AWS logging

### Tracing
- **Jaeger**: Distributed tracing
- **OpenTelemetry**: Instrumentation

### Security Monitoring
- **Falco**: Runtime threat detection
- **GuardDuty**: AWS threat intelligence
- **Security Hub**: Compliance dashboard

## 🌍 Multi-Environment Support

| Environment | Purpose     | Features                            |
|-------------|-------------|-------------------------------------|
| **dev**     | Development | Relaxed security, cost optimization |
| **stage**   | Staging     | Production-like, testing            |
| **prod**    | Production  | Full security, HA setup             |
|-------------|-------------|-------------------------------------|