provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_blueprints.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks_blueprints.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_blueprints.eks_cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_blueprints.eks_cluster_id
}

data "aws_availability_zones" "available" {}

locals {
  name = basename(path.cwd)
  # var.cluster_name is for Terratest
  cluster_name    = coalesce(var.cluster_name, local.name)
  cluster_version = "1.23"
  region          = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

#---------------------------------------------------------------
# EKS Blueprints
#---------------------------------------------------------------

module "eks_blueprints" {
  source = "../.."

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    # BottleRocket ships with kernel 5.10 so there is no need
    # to do anything special
    bottlerocket = {
      node_group_name = "mg5"
      instance_types  = ["m5.large"]
      min_size        = 2
      desired_size    = 2
      max_size        = 2
      ami_type        = "BOTTLEROCKET_x86_64"
    }
    # As of 10/23/2022, AL2 EKS AMI ships with kernel 5.4 therefore
    # we need to run a user-data script to update to 5.10, reboot
    # and then re-run the bootstrap.sh for worker node to join the
    # cluster
    amznlinux = {
      node_group_name        = "mng-lt"
      create_launch_template = true
      launch_template_os     = "amazonlinux2eks"
      ami_type               = "AL2_x86_64"
      pre_userdata           = <<-EOT
        --//
        Content-Type: text/x-shellscript; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="userdata1.txt"

        #x-shellscript-per-instance
        #!/bin/bash -ex
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
        amazon-linux-extras disable kernel-5.4
        amazon-linux-extras install kernel-5.10 -y
        reboot

        --//
        Content-Type: text/x-shellscript; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="userdata2.txt"

        #x-shellscript-per-boot
        #!/bin/bash -ex
        sudo /etc/eks/bootstrap.sh ${local.cluster_name}

        --//
        Content-Type: text/x-shellscript-per-boot; charset="us-ascii"
        MIME-Version: 1.0
        Content-Transfer-Encoding: 7bit
        Content-Disposition: attachment; filename="userdata.txt"
      EOT
      desired_size           = 2
      max_size               = 2
      min_size               = 2
      instance_types         = ["m5.large"]
    }
  }

  tags = local.tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "../../modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  # Wait on the `kube-system` profile before provisioning addons
  data_plane_wait_arn = module.eks_blueprints.managed_node_group_arn[0]

  # Add-ons
  enable_cilium           = true
  cilium_enable_wireguard = true

  tags = local.tags
}

#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

#---------------------------------------------------------------
# Sample App for Testing
#---------------------------------------------------------------

resource "kubectl_manifest" "server" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name = "server"
      labels = {
        blog = "wireguard"
        name = "server"
      }
    }
    spec = {
      containers = [
        {
          name  = "server"
          image = "nginx"
        }
      ]
      topologySpreadConstraints = [
        {
          maxSkew           = 1
          topologyKey       = "kubernetes.io/hostname"
          whenUnsatisfiable = "DoNotSchedule"
          labelSelector = {
            matchLabels = {
              blog = "wireguard"
            }
          }
        }
      ]
    }
  })
  depends_on = [
    module.eks_blueprints_kubernetes_addons
  ]
}

resource "kubectl_manifest" "service" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name = "server"
    }
    spec = {
      selector = {
        name = "server"
      }
      ports = [
        {
          port = 80
        }
      ]
    }
  })
}

resource "kubectl_manifest" "client" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name = "client"
      labels = {
        blog = "wireguard"
        name = "client"
      }
    }
    spec = {
      containers = [
        {
          name    = "client"
          image   = "busybox"
          command = ["watch", "wget", "server"]
        }
      ]
      topologySpreadConstraints = [
        {
          maxSkew : 1
          topologyKey       = "kubernetes.io/hostname"
          whenUnsatisfiable = "DoNotSchedule"
          labelSelector = {
            matchLabels = {
              blog = "wireguard"
            }
          }
        }
      ]
    }
  })
  depends_on = [
    kubectl_manifest.server
  ]
}