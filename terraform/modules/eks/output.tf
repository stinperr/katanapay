output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.this.status
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = try(local.oidc_issuer_url, aws_eks_cluster.this.identity[0].oidc[0].issuer)
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}

output "eks_addons" {
  description = "Map of EKS addons created"
  value = merge(
    {
      coredns = {
        arn           = aws_eks_addon.coredns.arn
        addon_version = aws_eks_addon.coredns.addon_version
      }
      kube_proxy = {
        arn           = aws_eks_addon.kube_proxy.arn
        addon_version = aws_eks_addon.kube_proxy.addon_version
      }
      vpc_cni = {
        arn           = aws_eks_addon.vpc_cni.arn
        addon_version = aws_eks_addon.vpc_cni.addon_version
      }
    },
    var.enable_irsa ? {
      ebs_csi_driver = {
        arn           = aws_eks_addon.ebs_csi_driver[0].arn
        addon_version = aws_eks_addon.ebs_csi_driver[0].addon_version
      }
    } : {}
  )
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, null)
}

output "oidc_provider_issuer_host" {
  description = "The OIDC Provider issuer host"
  value       = try(local.oidc_issuer_host, null)
}

output "oidc_provider_thumbprint" {
  description = "The OIDC Provider thumbprint"
  value       = try(data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint, null)
}

output "node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = aws_eks_node_group.this
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value = flatten([
    for group in aws_eks_node_group.this : group.resources[0].autoscaling_groups[*].name
  ])
}
