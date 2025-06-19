data "aws_iam_policy_document" "cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    security_group_ids      = var.cluster_additional_security_group_ids
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]

  tags = var.tags
}

resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = each.key
  addon_version            = try(each.value.addon_version, null)
  resolve_conflicts        = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn = try(each.value.service_account_role_arn, null)
  configuration_values     = try(each.value.configuration_values, null)

  tags = merge(var.tags, try(each.value.tags, {}))

  depends_on = [aws_eks_node_group.this]
}

data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node_group" {
  for_each = var.node_groups

  name               = "${var.cluster_name}-${each.key}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  for_each = var.node_groups

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[each.key].name
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.node_group[each.key].arn
  subnet_ids      = var.subnet_ids

  capacity_type  = try(each.value.capacity_type, "ON_DEMAND")
  instance_types = each.value.instance_types
  ami_type       = try(each.value.ami_type, "AL2_x86_64")
  disk_size      = try(each.value.disk_size, 20)

  scaling_config {
    desired_size = try(each.value.desired_size, 1)
    max_size     = try(each.value.max_size, 3)
    min_size     = try(each.value.min_size, 1)
  }

  dynamic "update_config" {
    for_each = try(each.value.update_config, null) != null ? [each.value.update_config] : []
    content {
      max_unavailable_percentage = try(update_config.value.max_unavailable_percentage, null)
      max_unavailable            = try(update_config.value.max_unavailable, null)
    }
  }

  dynamic "taint" {
    for_each = try(each.value.taints, [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = try(each.value.labels, {})

  tags = merge(var.tags, try(each.value.tags, {}))

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

locals {
  oidc_issuer_url  = aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_issuer_host = replace(local.oidc_issuer_url, "https://", "")
  oidc_issuer_arn  = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint
  ]

  url = local.oidc_issuer_url

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-irsa"
  })
}

data "aws_iam_policy_document" "irsa_assume_role_policy" {
  count = var.enable_irsa ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [local.oidc_issuer_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}
