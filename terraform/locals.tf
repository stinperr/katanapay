locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    Purpose     = "payment-microservice"
    Compliance  = "pci-dss"
    Terraform   = "true"
  }
}
