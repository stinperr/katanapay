output "eks_kms_key_arn" {
  description = "ARN of KMS key used for EKS secrets encryption"
  value       = aws_kms_key.eks.arn
}

output "eks_kms_key_id" {
  description = "ID of KMS key used for EKS secrets encryption"
  value       = aws_kms_key.eks.key_id
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "eks_additional_security_group_id" {
  description = "Additional security group ID for EKS cluster"
  value       = aws_security_group.eks_additional.id
}

output "payment_service_log_group_name" {
  description = "CloudWatch log group name for payment service"
  value       = aws_cloudwatch_log_group.payment_service.name
}

output "payment_service_log_group_arn" {
  description = "CloudWatch log group ARN for payment service"
  value       = aws_cloudwatch_log_group.payment_service.arn
}

output "eks_cluster_log_group_name" {
  description = "CloudWatch log group name for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "eks_cluster_log_group_arn" {
  description = "CloudWatch log group ARN for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}
