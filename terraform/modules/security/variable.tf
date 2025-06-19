variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
