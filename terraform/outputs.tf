output "cluster_name" {
  description = "EKS cluster name, or null while infrastructure is disabled."
  value       = try(aws_eks_cluster.main[0].name, null)
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint, or null while infrastructure is disabled."
  value       = try(aws_eks_cluster.main[0].endpoint, null)
}

output "kubeconfig_command" {
  description = "Run this command after the cluster has been created."
  value       = var.enable_cluster ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}" : null
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster."
  value       = aws_subnet.private[*].id
}
