module "payment_service_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-payment-service"
  role_description = "IAM role for payment service with least privilege access"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "payment"
      name      = "payment-service"
    }
  ]

  policy_statements = [
    {
      sid    = "AllowSecretsManagerAccess"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [
        "arn:aws:secretsmanager:*:${var.account_id}:secret:payment/*"
      ]
    },
    {
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      resources = [
        "arn:aws:logs:*:${var.account_id}:log-group:/aws/eks/${var.name_prefix}/*"
      ]
    },
    {
      sid    = "AllowKMSDecrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = [
        "arn:aws:kms:*:${var.account_id}:key/*"
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values = [
            "secretsmanager.*.amazonaws.com",
            "logs.*.amazonaws.com"
          ]
        }
      ]
    }
  ]

  tags = var.tags
}

module "ebs_csi_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-ebs-csi-driver"
  role_description = "IAM role for EBS CSI driver"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"
    }
  ]

  role_policy_arns = {
    ebs_csi = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  tags = var.tags
}

module "cluster_autoscaler_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-cluster-autoscaler"
  role_description = "IAM role for cluster autoscaler"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "cluster-autoscaler"
    }
  ]

  policy_statements = [
    {
      sid    = "AllowAutoScalingGroups"
      effect = "Allow"
      actions = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      resources = ["*"]
    }
  ]

  tags = var.tags
}

module "aws_load_balancer_controller_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-aws-load-balancer-controller"
  role_description = "IAM role for AWS Load Balancer Controller"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"
    }
  ]

  role_policy_arns = {
    alb_controller = "arn:aws:iam::${var.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
  }

  tags = var.tags
}

module "external_dns_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-external-dns"
  role_description = "IAM role for External DNS"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "kube-system"
      name      = "external-dns"
    }
  ]

  policy_statements = [
    {
      sid    = "AllowRoute53Access"
      effect = "Allow"
      actions = [
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ]
      resources = ["*"]
    }
  ]

  tags = var.tags
}

module "external_secrets_irsa" {
  source = "../irsa"

  role_name        = "${var.name_prefix}-external-secrets"
  role_description = "IAM role for External Secrets Operator"

  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_url = var.oidc_provider_url

  service_accounts = [
    {
      namespace = "external-secrets-system"
      name      = "external-secrets"
    }
  ]

  policy_statements = [
    {
      sid    = "AllowSecretsManagerAccess"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ]
      resources = [
        "arn:aws:secretsmanager:*:${var.account_id}:secret:payment/*",
        "arn:aws:secretsmanager:*:${var.account_id}:secret:eks/*"
      ]
    },
    {
      sid    = "AllowSSMParameterAccess"
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      resources = [
        "arn:aws:ssm:*:${var.account_id}:parameter/payment/*",
        "arn:aws:ssm:*:${var.account_id}:parameter/eks/*"
      ]
    }
  ]

  tags = var.tags
}
