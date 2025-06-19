variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path to the role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum CLI/API session duration in seconds between 3600 and 43200"
  type        = number
  default     = 3600
}

variable "role_permissions_boundary_arn" {
  description = "Permissions boundary ARN to use for IAM role"
  type        = string
  default     = null
}

variable "force_detach_policies" {
  description = "Whether policies should be detached from this role when destroying"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider"
  type        = string
}

variable "service_accounts" {
  description = "List of Kubernetes service accounts that can assume this role"
  type = list(object({
    namespace = string
    name      = string
  }))
}

variable "role_policy_arns" {
  description = "Map of ARNs of IAM policies to attach to IAM role"
  type        = map(string)
  default     = {}
}

variable "role_policies" {
  description = "Map of inline IAM policies to attach to IAM role"
  type        = map(string)
  default     = {}
}

variable "policy_statements" {
  description = "List of IAM policy statements to attach to the role"
  type        = any
  default     = []
}

variable "policy_path" {
  description = "Path to the policy"
  type        = string
  default     = "/"
}

variable "policy_description" {
  description = "Description of the IAM policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
