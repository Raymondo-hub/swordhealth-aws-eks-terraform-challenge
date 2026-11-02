# Reusable AWS Platform Infrastructure

This repository provisions reusable AWS infrastructure with Terraform. It does not deploy application workloads or Kubernetes manifests. Argo CD is bootstrapped into the cluster with Helm after infrastructure creation; application source, charts, and Argo CD application configuration belong in a separate application-delivery repository.

## What this repository provisions

- Reusable, environment-parameterized two-AZ VPC with public, private and isolated database subnets, per-AZ NAT gateways and tagged subnets for EKS and load balancer discovery.
- Private Amazon EKS API endpoint, private managed node group, control-plane logs, secrets encryption, EKS Pod Identity and VPC CNI network-policy enforcement.
- Private SSM administration instance with no inbound security-group rules.
- Private, encrypted RDS for MySQL, with RDS-managed master credentials in Secrets Manager and a security group restricted to EKS worker nodes.
- Daily AWS Backup recovery points retained for 35 days, weekly AWS Backup restore tests and seven-day native RDS point-in-time recovery.
- Two private, encrypted and versioned S3 buckets and an SQS queue.
- A scoped application IAM role and EKS Pod Identity association for the configurable application namespace/service account. Permissions are limited to list/get in the read bucket, put-object in the write bucket, and consuming messages from the queue.
- AWS Load Balancer Controller IAM role, policy and Pod Identity association. The separate delivery repo can install the controller with Helm/Argo CD and submit an Ingress; the controller then creates the internet-facing ALB. An ACM certificate can be provided by that repo for HTTPS.

No application image, Deployment, Service, Ingress, Kubernetes RBAC or NetworkPolicy manifest is managed here. The example image itself does not consume the provisioned database, buckets or queue; these resources and scoped permissions are infrastructure prerequisites for the challenge.

## Repository layout

```text
terraform/
  bootstrap/                 # One-time encrypted remote-state bucket
  environments/              # One shared root; dev/prod are input files and state keys
    dev.tfvars.example
    prod.tfvars.example
  modules/
    network/                 # VPC, subnets, endpoints
    eks/                     # Reusable private EKS module
    admin-role/              # SSM role for private cluster administration
    admin-host/              # Private SSM host and cluster security-group access
    mysql/                   # Private RDS MySQL and backup/restore
    app-dependencies/        # S3 buckets and SQS queue
    workload-identity/       # Application and ALB-controller Pod Identity
```

## Prerequisites

- Terraform 1.17.1 or later and AWS CLI v2.
- An AWS identity authorized to deploy the infrastructure.
- An existing IAM role for human administrators, supplied as `platform_admin_role_arn`.
- Permissions to create the listed AWS resources, pass the Terraform-created service roles, and manage the remote state bucket.
- For GitHub Actions, a GitHub OIDC provider and narrowly scoped plan/apply roles. Protect the `production` environment and main branch before enabling automatic apply.

Provisioning incurs charges for EKS, EC2, NAT gateways, interface endpoints, RDS, AWS Backup restore tests and (after an application Ingress is installed) the ALB. Review the plan before applying.

## 1. Create remote state storage

This is a one-time bootstrap. Keep the bootstrap state secure and retained.

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=swordhealth-tfstate-008003619776-us-east-1"
```

The bucket blocks public access, enables versioning and server-side encryption, and denies insecure transport.

## 2. Create an environment

The same Terraform root and modules are used for both environments; only the variable file and backend state key differ. The examples use non-overlapping VPC CIDRs. Adjust them if they conflict with existing networks.

```bash
cd ../environments
cp prod.tfvars.example prod.tfvars
# Edit the region, account-specific admin role, and CIDRs as needed.
terraform init \
  -backend-config="bucket=swordhealth-tfstate-008003619776-us-east-1" \
  -backend-config="region=us-east-1" \
  -backend-config="key=prod/eks/terraform.tfstate"
terraform fmt -check -recursive ../../
terraform validate
terraform plan -var-file=prod.tfvars -out=prod.tfplan
# Review estimated cost and all planned changes before applying.
terraform apply prod.tfplan
```

For dev, use a separate state key and variable file:

```bash
cp dev.tfvars.example dev.tfvars
# Edit the account-specific admin role and any environment-specific values.
terraform init -reconfigure \
  -backend-config="bucket=swordhealth-tfstate-008003619776-us-east-1" \
  -backend-config="region=us-east-1" \
  -backend-config="key=dev/eks/terraform.tfstate"
terraform plan -var-file=dev.tfvars -out=dev.tfplan
terraform apply dev.tfplan
```

Keep the private, public and database subnet CIDR lists non-overlapping and sized for the configured AZ count. The examples use two AZs. Dev uses one NAT gateway to reduce duplicated egress capacity; prod uses one per AZ. Keep `database_deletion_protection = true` for persistent environments. Set `application_namespace` and `application_service_account_name` to match the service account that the delivery repo will use.

The shared root retains the original production backend key, and `moved.tf` maps the former root-level resources into their new module addresses. For an existing production state, reinitialize with the same bucket, region and key as above; review the plan carefully and confirm Terraform reports state moves rather than destroying and recreating existing infrastructure.

AWS Backup restore testing runs weekly against the latest recovery point in the preceding seven days. To create a separate, temporary point-in-time restore manually, set `enable_point_in_time_restore_test = true`, plan and apply, inspect the restored endpoint, then set it back to `false` and apply to remove the test copy.

## 3. Access the private cluster

The EKS API endpoint has no public access. Use the private SSM administration host as a port-forwarding tunnel, while running `kubectl` on your workstation. This keeps Kubernetes authentication tied to your local AWS identity instead of the host's instance role. Install the AWS CLI v2 and Session Manager plugin locally, and sign in with an identity whose IAM role ARN is configured as `platform_admin_role_arn`.

In a first terminal, from `terraform/environments`, log in, configure kubeconfig, and point its API URL at the local tunnel:

```bash
export AWS_PROFILE=terraform-lab
export AWS_REGION=us-east-1
aws sso login --profile "$AWS_PROFILE"

CLUSTER_NAME="$(terraform output -raw cluster_name)"
CLUSTER_ENDPOINT="$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query 'cluster.endpoint' \
  --output text)"
CLUSTER_ENDPOINT_HOST="${CLUSTER_ENDPOINT#https://}"

aws eks update-kubeconfig \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --alias "$CLUSTER_NAME"
KUBECONFIG_CLUSTER="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}')"
kubectl config set-cluster "$KUBECONFIG_CLUSTER" \
  --server=https://127.0.0.1:8443 \
  --tls-server-name="$CLUSTER_ENDPOINT_HOST"
```

In a second terminal, from the same directory, start the remote-host port forward and leave it running:

```bash
export AWS_PROFILE=terraform-lab
export AWS_REGION=us-east-1
CLUSTER_NAME="$(terraform output -raw cluster_name)"
ADMIN_HOST_ID="$(terraform output -raw admin_host_instance_id)"
CLUSTER_ENDPOINT="$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --query 'cluster.endpoint' \
  --output text)"
CLUSTER_ENDPOINT_HOST="${CLUSTER_ENDPOINT#https://}"

aws ssm start-session \
  --target "$ADMIN_HOST_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$CLUSTER_ENDPOINT_HOST\"],\"portNumber\":[\"443\"],\"localPortNumber\":[\"8443\"]}" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"
```

Back in the first terminal, use `kubectl` locally:

```bash
kubectl get nodes
kubectl get pods -A
```

The IAM role configured as `platform_admin_role_arn` currently receives cluster-admin access. Prefer a dedicated, tightly controlled operator role, and grant only the Kubernetes permissions operators need. Restrict SSM access to the intended administration host and port-forwarding document; anyone permitted to open an unrestricted shell on that host can use its instance role, which is also authorized as a cluster administrator. The private host can also serve as the network entry point for private Argo CD bootstrap or other administration. Public GitHub-hosted runners cannot reach the private Kubernetes API.

## 4. Bootstrap and access Argo CD

Argo CD and application deployment are managed from the separate delivery repository, not by this Terraform root. After applying the infrastructure, pushing the delivery repository to its configured `main` branch, and establishing the SSM tunnel to the private EKS API, run `./scripts/bootstrap-argocd.sh` from the delivery repository. The idempotent script installs or upgrades the pinned Argo CD Helm chart and applies its root Application. See the delivery repository README for prerequisites and details.

The Argo CD server remains a private `ClusterIP`. To access it, run this in another terminal while the SSM tunnel is active:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Open <https://localhost:8080> in a browser. The initial certificate is self-signed, so the browser may display a certificate warning. Retrieve the one-time initial admin password on macOS with:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -D
echo
```

On Linux, use `base64 -d` instead of `base64 -D`. Sign in as `admin`, change the initial password, then delete the initial password secret:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

The Argo CD Helm release is deliberately outside this Terraform root. The delivery repository's `scripts/bootstrap-argocd.sh` is the canonical, repeatable install/upgrade command and uses the existing `argocd` Helm release name; rerunning it reconciles that release rather than creating a second one. Do not manage this chart from Terraform or install another Argo CD release. The delivery repository owns the Helm bootstrap and GitOps application definitions. Configure SSO and least-privilege Argo CD RBAC before onboarding other users.

## 5. Integrate the delivery repository

Use the infrastructure outputs to configure the separate application-delivery repo and its Helm/Argo CD values:

```bash
terraform output
```

Relevant values include the cluster name, VPC ID, private subnet IDs, public subnet CIDRs, application role ARN, application namespace and service account, bucket names, SQS queue URL, database endpoint and managed master-secret ARN, and load balancer controller role ARN.

The application chart should use the configured namespace/service account so EKS Pod Identity can provide the scoped AWS role. The delivery repo owns the AWS Load Balancer Controller Helm release, application chart/manifests, Ingress and Kubernetes policies. The Ingress should use the ALB controller and the public subnets tagged by this infrastructure. If HTTPS is required, supply an ACM certificate ARN from the same AWS region to the delivery repo.

## GitHub Actions

The GitHub OIDC provider and plan/apply roles are managed separately from the EKS environment, in `terraform/github-actions` and the reusable `terraform/modules/github-oidc` module. This root has its own state key so destroying or recreating EKS does not remove the identities needed to run Terraform.

The existing OIDC provider, `GitHubActionsTerraformPlan` role, `GitHubActionsTerraformApply` role, plan-role policy attachment, and apply-role state policy are imported into this root's state. The previous `PowerUserAccess` attachment is absent, so Terraform creates the scoped apply policy attachment instead of trying to import it. Review the plan before applying. Use a trusted operator AWS profile with IAM permissions and access to the state bucket; do not use either GitHub role to bootstrap itself.

```bash
export AWS_PROFILE=terraform-lab
aws sso login --profile "$AWS_PROFILE"
cd terraform/github-actions
terraform init \
  -backend-config="bucket=swordhealth-tfstate-008003619776-us-east-1" \
  -backend-config="region=us-east-1" \
  -backend-config="key=iam/github-actions/terraform.tfstate"
terraform fmt -check -recursive ../
terraform validate
terraform plan -out=github-actions.tfplan
# Review all imports and policy changes before applying.
terraform apply github-actions.tfplan
```

The root manages production state access, project-scoped IAM deployment permissions, and the OIDC trust subjects. The plan role is limited to the main branch and same-repository pull requests; the apply role requires the `production` GitHub environment. Restrict that environment to the `main` branch and configure required reviewers before enabling production applies. The plan role uses a custom read-only policy rather than AWS-managed `ReadOnlyAccess`: S3 access is limited to bucket configuration for the two application buckets and the production state/lock objects, while infrastructure discovery is limited to the services this Terraform root manages. Some AWS `List`/`Describe` operations require `Resource = "*"`, so those statements are restricted to the configured region where AWS supports that condition.

After applying, configure repository variables `AWS_REGION`, `TF_STATE_BUCKET`, `EKS_ADMIN_ROLE_ARN`, `AWS_TERRAFORM_PLAN_ROLE_ARN`, and `AWS_TERRAFORM_APPLY_ROLE_ARN`. Use the Terraform outputs for the two GitHub role ARNs. The production workflow in `.github/workflows/terraform-prod.yml` uses the shared `terraform/environments` root and production state key, formats, validates, plans, then applies the exact plan artifact. Plans and artifacts can contain sensitive infrastructure data: keep the repository private, limit repository read access to trusted collaborators, and retain the artifact only as long as needed. The workflow currently expires it after one day. Development is applied independently using its own state key.

The Terraform-managed apply role replaces the existing AWS-managed `PowerUserAccess` attachment with a custom infrastructure policy and attaches the `GitHubActionsTerraformProductionBoundary` permissions boundary. The boundary scopes EKS to the named cluster and its child resources, RDS to production name prefixes, Backup to the production vault/plans, CloudWatch Logs to the EKS log group, KMS to project-tagged keys and named aliases, S3 to the two production buckets and Terraform state objects, SQS to the application queue, and IAM role/policy operations to the project path. EC2 operations are region-limited and require project tags for existing resources or tagged creation requests. Standalone EC2 tagging is explicitly denied to prevent adopting unrelated resources by adding the project tag. The apply role cannot modify either GitHub role or its permissions boundary.

The boundary is an upper limit, not a grant by itself. The custom infrastructure policy grants the service actions; state and IAM permissions are separately scoped. The apply role can access only the production state object and lock object for backend operations; its general S3 permissions cover the two application buckets, not the state bucket. The boundary is kept below IAM's 6,144-character customer-managed policy limit, and Terraform checks the rendered policy size before apply. **The service-role permissions are narrower than `PowerUserAccess`, but not fully resource-level least privilege:** EC2, EKS, RDS, AWS Backup, CloudWatch Logs, KMS, and some read-only inventory actions still require wildcard resources within the allowed region/service families. Review CloudTrail/IAM Access Analyzer evidence and refine those ARNs and actions before treating the policy as a production least-privilege control. Kubernetes deployment is intentionally outside this workflow and repository.

## Database recovery

- RDS native automated backups retain seven days and support point-in-time recovery.
- AWS Backup takes daily recovery points in a dedicated vault and retains them for 35 days.
- AWS Backup runs a weekly restore test. The temporary restore resources are managed by AWS Backup and can incur additional charges.
- An operator-triggered Terraform point-in-time restore can be enabled using `enable_point_in_time_restore_test`; it creates a separate test DB instance and does not replace production.
- Keep state access restricted and encrypted. The state bucket blocks public access, enables versioning and SSE-S3 encryption, and denies insecure transport; backend access uses separate plan/apply permissions scoped to the production state and lock objects. Terraform state and saved plans still contain sensitive infrastructure metadata, even though RDS manages the master password in Secrets Manager. Restrict repository/artifact access and test state-version recovery before depending on it.

## Tear down

Remove application resources through the delivery repo first. Then destroy the AWS infrastructure root when appropriate. Disable RDS deletion protection before destroying persistent environments; retain required database snapshots and state backups. Delete the bootstrap state bucket only after all environment states have been safely retired.
