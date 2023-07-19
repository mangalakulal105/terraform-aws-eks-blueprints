variable "managed_node_group" {
  description = "Managed Node Group"
  type = object({
    node_group_name = string
    instance_types  = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
  })
  default = {
    node_group_name = "managed-ondemand"
    instance_types  = ["t3.small"]
    min_size        = 1
    max_size        = 3
    desired_size    = 2
  }
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "private-eks-cluster"
}

variable "endpoint_service_name" {
  description = "Name of the VPC endpoint service"
  type        = string
  default     = "k8s-api-server-eps"
}

variable "endpoint_name" {
  description = "Name of the VPC endpoint"
  type        = string
  default     = "k8s-api-server-ep"
}

variable "handle_eni_cleanup_lambda_freq" {
  description = "Frequency in mins, how often the clean up lambda needs to run"
  type        = number
  default     = 15
}
