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

resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = var.cluster_id
  addon_name               = local.eks_addon_kube_proxy_config["addon_name"]
  addon_version            = local.eks_addon_kube_proxy_config["addon_version"]
  resolve_conflicts        = local.eks_addon_kube_proxy_config["resolve_conflicts"]
  service_account_role_arn = local.eks_addon_kube_proxy_config["service_account_role_arn"]
  tags = merge(
    var.common_tags, local.eks_addon_kube_proxy_config["tags"],
    { "eks_addon" = "kube-proxy" }
  )

}
