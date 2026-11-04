# Security Policy

## Scope

This repository is a learning project for Terraform, Amazon EKS, Kubernetes and Argo CD. It is not a production-hardened platform.

## Reporting

Do not publish credentials, tokens, private keys, or exploitable details in a public issue. Use GitHub's private vulnerability reporting feature when available.

## Safe usage

- Never commit AWS access keys, session tokens, GitHub tokens, private keys, kubeconfig files, Terraform state, or real terraform.tfvars files.
- Use IAM Identity Center or short-lived role credentials instead of long-lived IAM user keys.
- Restrict the EKS public API endpoint to a trusted IP range. Do not use 0.0.0.0/0.
- Keep worker nodes in private subnets.
- Use least-privilege IAM policies and review AWS plans before applying.
- Make the GHCR package public only if intended for public access. Otherwise configure an image pull secret without committing its token.
- Destroy lab infrastructure when it is no longer required and verify AWS resources were removed.
