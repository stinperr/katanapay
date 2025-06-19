output "payment_service_role_arn" {
  description = "ARN of IAM role for payment service"
  value       = module.payment_service_irsa.iam_role_arn
}

output "payment_service_role_name" {
  description = "Name of IAM role for payment service"
  value       = module.payment_service_irsa.iam_role_name
}

output "ebs_csi_role_arn" {
  description = "ARN of IAM role for EBS CSI driver"
  value       = module.ebs_csi_irsa.iam_role_arn
}

output "ebs_csi_role_name" {
  description = "Name of IAM role for EBS CSI driver"
  value       = module.ebs_csi_irsa.iam_role_name
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of IAM role for cluster autoscaler"
  value       = module.cluster_autoscaler_irsa.iam_role_arn
}

output "cluster_autoscaler_role_name" {
  description = "Name of IAM role for cluster autoscaler"
  value       = module.cluster_autoscaler_irsa.iam_role_name
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of IAM role for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa.iam_role_name
}

output "external_dns_role_arn" {
  description = "ARN of IAM role for External DNS"
  value       = module.external_dns_irsa.iam_role_arn
}

output "external_dns_role_name" {
  description = "Name of IAM role for External DNS"
  value       = module.external_dns_irsa.iam_role_name
}

output "external_secrets_role_arn" {
  description = "ARN of IAM role for External Secrets"
  value       = module.external_secrets_irsa.iam_role_arn
}

output "external_secrets_role_name" {
  description = "Name of IAM role for External Secrets"
  value       = module.external_secrets_irsa.iam_role_name
}
