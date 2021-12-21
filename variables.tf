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

#  CLUSTER LABELS
variable "org" {
  type        = string
  description = "tenant, which could be your organization name, e.g. aws'"
  default     = ""
}

variable "tenant" {
  type        = string
  description = "Account Name or unique account unique id e.g., apps or management or aws007"
  default     = "aws"
}

variable "environment" {
  type        = string
  default     = "preprod"
  description = "Environment area, e.g. prod or preprod "
}

variable "zone" {
  type        = string
  description = "zone, e.g. dev or qa or load or ops etc..."
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "terraform_version" {
  type        = string
  default     = "Terraform"
  description = "Terraform Version"
}

# VPC Config for EKS Cluster
variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "private_subnet_ids" {
  description = "list of private subnets Id's for the Worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "list of public subnets Id's for the Worker nodes"
  type        = list(string)
  default     = []
}

# EKS CONTROL PLANE
variable "create_eks" {
  type        = bool
  default     = false
  description = "Enable Create EKS"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.21"
  description = "Desired Kubernetes master version. If you do not specify a value, the latest available version is used"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = false
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
}

variable "enable_irsa" {
  type        = bool
  default     = true
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true"
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable"
}

variable "cluster_log_retention_period" {
  type        = number
  default     = 7
  description = "Number of days to retain cluster logs"
}

# EKS MANAGED ADDONS
variable "eks_addon_vpc_cni_config" {
  description = "Map of Amazon EKS VPC CNI Add-on"
  type        = any
  default     = {}
}

variable "eks_addon_coredns_config" {
  description = "Map of Amazon COREDNS EKS Add-on"
  type        = any
  default     = {}
}

variable "eks_addon_kube_proxy_config" {
  description = "Map of Amazon EKS KUBE_PROXY Add-on"
  type        = any
  default     = {}
}

variable "eks_addon_aws_ebs_csi_driver_config" {
  description = "Map of Amazon EKS aws_ebs_csi_driver Add-on"
  type        = any
  default     = {}
}

variable "enable_eks_addon_vpc_cni" {
  type        = bool
  default     = false
  description = "Enable VPC CNI Addon"
}

variable "enable_eks_addon_coredns" {
  type        = bool
  default     = false
  description = "Enable CoreDNS Addon"
}

variable "enable_eks_addon_kube_proxy" {
  type        = bool
  default     = false
  description = "Enable Kube Proxy Addon"
}

variable "enable_eks_addon_aws_ebs_csi_driver" {
  type        = bool
  default     = false
  description = "Enable EKS Managed EBS CSI Driver Addon"
}

# EKS WORKER NODES
variable "managed_node_groups" {
  description = "Managed Node groups configuration"
  type        = any
  default     = {}
}

variable "self_managed_node_groups" {
  description = "Self-Managed Node groups configuration"
  type        = any
  default     = {}
}

variable "fargate_profiles" {
  description = "Fargate Profile configuration"
  type        = any
  default     = {}
}

# EKS WINDOWS SUPPORT
variable "enable_windows_support" {
  description = "Enable Windows support"
  type        = bool
  default     = false
}

# CONFIGMAP AWS-AUTH
variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. "
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. "
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_additional_labels" {
  description = "Additional kubernetes labels applied on aws-auth ConfigMap"
  default     = {}
  type        = map(string)
}

#-----------Amazon Managed Prometheus-------------
variable "aws_managed_prometheus_enable" {
  type        = bool
  default     = false
  description = "Enable AWS Managed Prometheus service"
}

variable "aws_managed_prometheus_workspace_id" {
  type        = string
  default     = ""
  description = "AWS Managed Prometheus WorkSpace Name"
}

#-----------Amazon EMR on EKS-------------
variable "enable_emr_on_eks" {
  type        = bool
  default     = false
  description = "Enabling EMR on EKS Config"
}

variable "emr_on_eks_teams" {
  description = "EMR on EKS Teams configuration"
  type        = any
  default     = {}
}

#-----------TEAMS-------------
variable "application_teams" {
  description = "Map of maps of Application Teams to create"
  type        = any
  default     = {}
}

variable "platform_teams" {
  description = "Map of maps of platform teams to create"
  type        = any
  default     = {}
}
