locals {
  name = "kubecost"

  default_helm_config = {
    name             = local.name
    chart            = "cost-analyzer"
    repository       = "oci://public.ecr.aws/kubecost"
    version          = "1.96.0"
    namespace        = local.name
    create_namespace = true
    description      = "Kubecost Helm Chart deployment configuration"
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config,
    { values = distinct(concat(try(var.helm_config["values"], []), local.default_helm_values)) }
  )

  default_helm_values = [templatefile("${path.module}/values.yaml", {})]

  argocd_gitops_config = {
    enable = true
  }
}
