##############################################
# AWS AUTH CONFIGMAP APPLY (FINAL CLEAN VERSION)
##############################################

resource "null_resource" "aws_auth" {
  count = length(module.eks)

  provisioner "local-exec" {
    command = <<EOT
set -e

# Set variables
CLUSTER_NAME="${module.eks[count.index].cluster_name}"
NODE_ROLE_ARN="${module.eks[count.index].node_role_arn}"
REGION="ap-south-1"

echo "Updating kubeconfig for $CLUSTER_NAME..."

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$REGION"

# Create aws-auth yaml
cat > aws-auth-${count.index}.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $NODE_ROLE_ARN
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

# Add admin users (if any)
%{ if length(var.admin_user_arns) > 0 }
echo "  mapUsers: |" >> aws-auth-${count.index}.yaml
%{ for u in var.admin_user_arns ~}
echo "    - userarn: ${u}" >> aws-auth-${count.index}.yaml
echo "      username: admin" >> aws-auth-${count.index}.yaml
echo "      groups: [\\"system:masters\\"]" >> aws-auth-${count.index}.yaml
%{ endfor ~}
%{ endif }

echo "Applying aws-auth for $CLUSTER_NAME ..."
kubectl apply -f aws-auth-${count.index}.yaml

EOT
    interpreter = ["/bin/bash", "-c"]
  }

  triggers = {
    cluster_name  = module.eks[count.index].cluster_name
    node_role_arn = module.eks[count.index].node_role_arn
    admins        = join(",", var.admin_user_arns)
  }
}
