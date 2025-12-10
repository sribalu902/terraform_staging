##############################################
# AWS AUTH CONFIGMAP APPLY (PRIVATE EKS SAFE)
##############################################

resource "null_resource" "aws_auth" {
  count = length(module.eks)

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -e

CLUSTER_NAME="${module.eks[count.index].cluster_name}"
NODE_ROLE_ARN="${module.eks[count.index].node_role_arn}"
REGION="$(aws configure get region)"

echo "Updating kubeconfig for cluster: $CLUSTER_NAME"

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION" \
  --role-arn "${var.admin_role_arn}"

echo "Generating aws-auth ConfigMap..."

cat > aws-auth-${count.index}.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $${NODE_ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

###############################################
# ADD ADMIN ROLE
###############################################
echo "  mapRoles: |" >> aws-auth-${count.index}.yaml
echo "    - rolearn: ${var.admin_role_arn}" >> aws-auth-${count.index}.yaml
echo "      username: admin" >> aws-auth-${count.index}.yaml
echo "      groups:" >> aws-auth-${count.index}.yaml
echo "        - system:masters" >> aws-auth-${count.index}.yaml

###############################################
# ADD ADMIN USERS (Optional)
###############################################
%{ if length(var.admin_user_arns) > 0 }
echo "  mapUsers: |" >> aws-auth-${count.index}.yaml
%{ for u in var.admin_user_arns ~}
echo "    - userarn: ${u}" >> aws-auth-${count.index}.yaml
echo "      username: admin-user" >> aws-auth-${count.index}.yaml
echo "      groups:" >> aws-auth-${count.index}.yaml
echo "        - system:masters" >> aws-auth-${count.index}.yaml
%{ endfor ~}
%{ endif }

echo "Applying aws-auth to $CLUSTER_NAME..."

kubectl apply -f aws-auth-${count.index}.yaml

EOT
  }

  triggers = {
    cluster = module.eks[count.index].cluster_name
    role    = module.eks[count.index].node_role_arn
    admins  = join(",", var.admin_user_arns)
  }
}
