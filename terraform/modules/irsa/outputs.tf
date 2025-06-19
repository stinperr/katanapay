output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = aws_iam_role.this.name
}

output "iam_role_path" {
  description = "Path of IAM role"
  value       = aws_iam_role.this.path
}

output "iam_role_unique_id" {
  description = "Unique ID of IAM role"
  value       = aws_iam_role.this.unique_id
}

output "iam_policy_arn" {
  description = "ARN of IAM policy"
  value       = try(aws_iam_policy.this[0].arn, null)
}

output "iam_policy_name" {
  description = "Name of IAM policy"
  value       = try(aws_iam_policy.this[0].name, null)
}

output "iam_policy_id" {
  description = "ID of IAM policy"
  value       = try(aws_iam_policy.this[0].id, null)
}
