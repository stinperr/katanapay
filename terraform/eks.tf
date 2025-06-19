module "eks" {
  source = "./modules/eks"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_additional_security_group_ids = [module.security.eks_additional_security_group_id]

  cluster_addons = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.7"
    }
    kube-proxy = {
      addon_version = "v1.29.0-eksbuild.1"
    }
    vpc-cni = {
      addon_version = "v1.16.0-eksbuild.1"
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          ENABLE_POD_ENI           = "true"
        }
      })
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.26.1-eksbuild.1"
      service_account_role_arn = module.iam.ebs_csi_role_arn
    }
  }

  node_groups = {
    payment_service = {
      name           = "payment-service"
      instance_types = [var.node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      disk_size      = 50
      disk_type      = "gp3"
      disk_encrypted = true

      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"

      labels = {
        Environment = var.environment
        NodeGroup   = "payment-service"
      }

      taints = [
        {
          key    = "payment-service"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }

  enable_irsa = true
  kms_key_arn = module.security.eks_kms_key_arn

  tags = local.common_tags
}
