/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

# ---------------------------------------------------------------------------------------------------------------------
# LABELING EKS RESOURCES
# ---------------------------------------------------------------------------------------------------------------------
module "eks_tags" {
  source      = "./modules/aws-resource-tags"
  tenant      = var.tenant
  environment = var.environment
  zone        = var.zone
  resource    = "eks"
  tags        = local.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS CONTROL PLANE
# ---------------------------------------------------------------------------------------------------------------------
#TODO Create KMS alias and assign it
resource "aws_kms_key" "eks" {
  description = "EKS Cluster Secret Encryption Key"
}

module "aws_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v17.20.0"

  create_eks      = var.create_eks
  manage_aws_auth = false

  cluster_name    = module.eks_tags.id
  cluster_version = var.kubernetes_version

  # NETWORK CONFIG
  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # IRSA
  enable_irsa            = var.enable_irsa
  kubeconfig_output_path = "./kubeconfig/"

  # TAGS
  tags = module.eks_tags.tags

  # CLUSTER LOGGING
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # CLUSTER ENCRYPTION
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS Managed Prometheus Module
# ---------------------------------------------------------------------------------------------------------------------

module "aws_managed_prometheus" {
  count  = var.create_eks && var.enable_aws_managed_prometheus == true ? 1 : 0
  source = "./modules/aws-managed-prometheus"

  environment                     = var.environment
  tenant                          = var.tenant
  zone                            = var.zone
  account_id                      = data.aws_caller_identity.current.account_id
  region                          = data.aws_region.current.id
  eks_cluster_id                  = module.aws_eks.cluster_id
  eks_oidc_provider               = split("//", module.aws_eks.cluster_oidc_issuer_url)[1]
  service_account_amp_ingest_name = local.aws_managed_prometheus_ingest_service_account
  service_account_amp_query_name  = local.aws_managed_prometheus_query_service_account
  amp_workspace_name              = var.aws_managed_prometheus_workspace_id == "" ? local.aws_managed_prometheus_workspace_id : var.aws_managed_prometheus_workspace_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Amazon EMR on EKS Virtual Clusters
# ---------------------------------------------------------------------------------------------------------------------

module "emr_on_eks" {
  source = "./modules/emr-on-eks"

  for_each = { for key, value in var.emr_on_eks_teams : key => value
    if var.enable_emr_on_eks && length(var.emr_on_eks_teams) > 0
  }

  emr_on_eks_teams = each.value

  eks_cluster_id = module.aws_eks.cluster_id
  environment    = var.environment
  tenant         = var.tenant
  zone           = var.zone
  tags           = var.tags

  depends_on = [module.aws_eks, kubernetes_config_map.aws_auth]

}

resource "kubernetes_config_map" "amazon_vpc_cni" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    "enable-windows-ipam" = var.enable_windows_support ? "true" : "false"
  }

  depends_on = [
    module.aws_eks
  ]
}
