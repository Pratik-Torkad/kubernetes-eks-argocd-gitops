variable "enable_cluster" {
  description = "Must be true to create billable AWS networking and EKS resources."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for the EKS lab."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  type        = string
  default     = "gitops-eks-lab"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version. Check AWS supported versions before provisioning."
  type        = string
  default     = "1.37"
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs, one per Availability Zone."
  type        = list(string)
  default     = ["10.40.0.0/20", "10.40.16.0/20"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Provide exactly two public subnet CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs, one per Availability Zone."
  type        = list(string)
  default     = ["10.40.128.0/20", "10.40.144.0/20"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Provide exactly two private subnet CIDRs."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Allow a public EKS API endpoint, restricted by the CIDR list below."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Trusted public IP ranges in CIDR notation. Required when enabling a public EKS endpoint."
  type        = list(string)
  default     = []

  validation {
    condition = (
      !var.enable_cluster ||
      !var.cluster_endpoint_public_access ||
      (
        length(var.cluster_endpoint_public_access_cidrs) > 0 &&
        alltrue([
          for cidr in var.cluster_endpoint_public_access_cidrs :
          cidr != "0.0.0.0/0" && cidr != "::/0"
        ])
      )
    )
    error_message = "When enabling the cluster with a public endpoint, provide trusted CIDRs and never use 0.0.0.0/0 or ::/0."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired worker node count for the lab."
  type        = number
  default     = 1

  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 2
    error_message = "For this cost-conscious lab, desired node count must be 1 or 2."
  }
}
