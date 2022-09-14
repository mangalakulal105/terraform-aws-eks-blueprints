locals {
  name = "spark-history-server"

  default_helm_config = {
    name        = local.name
    chart       = local.name
    repository  = "https://hyper-mesh.github.io/spark-history-server"
    version     = "1.0.0"
    namespace   = local.name
    description = "Helm chart for deploying Spark WebUI with Spark History Server in EKS using S3 Spark Event logs"
    timeout     = "300"
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config,
    { values = distinct(concat(try(var.helm_config["values"], []), local.default_helm_values)) }
  )

  set_values = [{
    name  = "serviceAccount.name"
    value = local.name
    },
    {
      name  = "serviceAccount.create"
      value = false
    }
  ]

  irsa_config = {
    kubernetes_namespace              = local.helm_config["namespace"]
    kubernetes_service_account        = local.name
    create_kubernetes_namespace       = try(local.helm_config["create_namespace"], true)
    create_kubernetes_service_account = true
    irsa_iam_policies                 = length(var.irsa_policies) > 0 ? var.irsa_policies : ["arn:${var.addon_context.aws_partition_id}:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", {
    s3a_path         = var.s3a_path
    operating_system = "linux"
  })]

  argocd_gitops_config = {
    enable = true
  }
}
