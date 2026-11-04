# Kubernetes on AWS EKS with Argo CD GitOps

A learning project for Terraform-managed Amazon EKS, Kubernetes workloads, and GitOps reconciliation with Argo CD.

> **Cost safety:** Terraform defaults to enable_cluster = false. No AWS resources are created until you deliberately enable the cluster and review the plan. EKS control-plane hours, EC2 nodes, EBS, NAT Gateway, data transfer, and logs can incur charges.

## Architecture

~~~mermaid
flowchart LR
  Dev[Developer] --> Git[GitHub]
  Git --> CI[GitHub Actions validation]
  Git --> Argo[Argo CD]
  Terraform[Terraform] --> VPC[VPC and subnets]
  VPC --> EKS[Amazon EKS]
  Argo --> EKS
  EKS --> Pods[Kubernetes Deployment and Service]
  Pods --> Image[Flask container in GHCR]
~~~

## Included

- Terraform configuration for a VPC, two public/private subnet pairs, routing, IAM roles, EKS cluster and managed node group.
- Kubernetes namespace, Deployment and ClusterIP Service, with probes and container resource limits.
- Argo CD Application watching this repository's main branch and kubernetes/app directory.
- GitHub Actions for Terraform formatting/validation and Kubernetes manifest schema checks.
- Safety defaults, EKS API CIDR restrictions, and teardown instructions.

## Prerequisites

AWS account and suitable IAM permissions; AWS CLI v2; Terraform 1.10+; kubectl; Git; and permission to pull the Project 2 image from GitHub Container Registry.

Never commit credentials, kubeconfig, Terraform state, or terraform.tfvars.

## 1. Configure AWS credentials

For IAM Identity Center:

~~~bash
aws configure sso
aws sso login --profile YOUR_PROFILE
aws sts get-caller-identity --profile YOUR_PROFILE
export AWS_PROFILE=YOUR_PROFILE
~~~

Use a dedicated least-privilege identity. Do not use root access keys.

## 2. Configure Terraform

~~~bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
~~~

Edit terraform.tfvars. To create infrastructure, set enable_cluster = true and provide your own public IPv4 address as a CIDR in cluster_endpoint_public_access_cidrs, for example ["YOUR_PUBLIC_IP/32"].

Find the current public IPv4 address:

~~~bash
curl -4 https://checkip.amazonaws.com
~~~

Do not use 0.0.0.0/0. Keep the endpoint CIDR limited to trusted IPs.

The default Kubernetes version is 1.37, which AWS lists as standard-support on 4 November 2026. Check the current lifecycle before provisioning: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html

## 3. Validate and review the plan

From the terraform directory:

~~~bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
~~~

With the example variables unchanged, enable_cluster is false and Terraform should propose no VPC or EKS resources.

Only after reviewing the plan, region, network CIDRs, security, and costs should you enable the cluster and run:

~~~bash
terraform apply -var-file=terraform.tfvars
~~~

This lab creates one managed t3.medium worker and one NAT Gateway. It is not a production or highly available deployment. Review https://aws.amazon.com/eks/pricing/ and configure AWS Budgets before creating resources.

## 4. Connect kubectl

After the cluster has been created:

~~~bash
aws eks update-kubeconfig --region ap-south-1 --name gitops-eks-lab
kubectl get nodes
~~~

Change region/name if you changed the Terraform variables.

## 5. Install Argo CD

~~~bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server --timeout=5m
kubectl port-forward svc/argocd-server -n argocd 8080:443
~~~

Open https://localhost:8080. Retrieve the initial admin password locally:

~~~bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
~~~

Change the initial password after first login. Never put it in GitHub or this chat.

## 6. Register the GitOps application

From the repository root:

~~~bash
kubectl apply -f argocd/applications/flask-demo.yaml
kubectl get applications -n argocd
kubectl get pods,services -n gitops-demo
~~~

Argo CD watches the main branch and automatically syncs changes, prunes removed resources, and self-heals drift.

The deployment uses the Project 2 image tag:

~~~text
ghcr.io/pratik-torkad/flask-cicd-demo:sha-609d81a
~~~

The GHCR package must be public for anonymous image pulls. If it is private, create a Kubernetes image pull secret using a least-privilege GitHub token with read-only package access, and reference it from the Deployment. Never commit the token.

## 7. Test the application

~~~bash
kubectl get deployment,service,pods -n gitops-demo
kubectl port-forward svc/flask-demo -n gitops-demo 5000:80
curl http://localhost:5000/health
~~~

Open http://localhost:5000. The sample Flask service exposes / and /health.

## 8. Destroy lab infrastructure

When finished, run from the terraform directory:

~~~bash
terraform destroy -var-file=terraform.tfvars
~~~

Review the destroy plan before confirming. Verify the EKS cluster, node group, NAT Gateway, Elastic IP, VPC, and related resources have been removed. A separately created S3 state bucket is not managed by this configuration.

## Security and cost notes

- EKS cluster-hours continue while the cluster exists.
- EC2, EBS, NAT Gateway-hours/data processing, data transfer, and optional logs can add charges.
- Stopping pods does not stop EKS or NAT Gateway charges.
- EKS public API access is restricted by the trusted CIDR list; worker nodes run in private subnets.
- One worker node is for learning only, not high availability.
- Use SSO/MFA, short-lived credentials, least privilege, budgets, and destroy resources when finished.

## Validation

CI checks code formatting, Terraform configuration, and Kubernetes application schemas. A successful validation workflow does not mean AWS resources were deployed; CI never creates a cluster.

Related Project 2: https://github.com/Pratik-Torkad/github-actions-docker-cicd
