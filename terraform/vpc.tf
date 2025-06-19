module "vpc" {
  source = "./modules/vpc"

  name = module.null_labels.name
  cidr = var.vpc_cidr

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  isolated_subnets = var.isolated_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  enable_flow_log            = true
  flow_log_retention_in_days = 30

  tags = local.common_tags
}
