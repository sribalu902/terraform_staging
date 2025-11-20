############################################
# aws-auth for cluster 0 (cds)
############################################
# resource "kubernetes_config_map" "aws_auth_cds" {
#   provider = kubernetes.cds

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = module.eks[0].node_role_arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])
#     mapUsers = yamlencode([
#       {
#         userarn  = var.admin_user_arn
#         username = "admin"
#         groups   = ["system:masters"]
#       }
#     ])
#   }
# }

# ############################################
# # aws-auth for cluster 1 (bap)
# ############################################
# resource "kubernetes_config_map" "aws_auth_bap" {
#   provider = kubernetes.bap

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = module.eks[1].node_role_arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])
#     mapUsers = yamlencode([
#       {
#         userarn  = var.admin_user_arn
#         username = "admin"
#         groups   = ["system:masters"]
#       }
#     ])
#   }
# }
############################################
# DYNAMIC AWS-AUTH (NO hard-coded clusters)
############################################
resource "kubernetes_config_map" "aws_auth" {
  for_each = module.eks

  provider = kubernetes[each.key]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = each.value.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])

    mapUsers = yamlencode([
      {
        userarn  = var.admin_user_arn
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }
}
