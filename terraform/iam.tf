module "security" {
  source = "./modules/security"

  name_prefix = local.name
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr

  tags = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  account_id        = data.aws_caller_identity.current.account_id

  tags = local.common_tags

  depends_on = [module.eks]
}
