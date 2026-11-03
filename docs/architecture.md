# AWS platform architecture

This diagram describes the production configuration across the infrastructure and delivery repositories. Terraform creates the AWS foundation and EKS access prerequisites; the delivery repository bootstraps Argo CD with Helm and stores the GitOps configuration.

## Production overview

```mermaid
flowchart TB
    Internet((Internet))
    Operator[Platform operator]
    GitHubInfra[GitHub Actions<br/>Terraform plan and apply]
    GitHubDelivery[GitHub repository<br/>swordhealth-deploy]
    DockerHub[Docker Hub<br/>node-example image]

    subgraph AWS["AWS account · us-east-1"]
        subgraph VPC["Production VPC · 10.20.0.0/16 · two Availability Zones"]
            subgraph Public["Public subnets · internet-facing"]
                ALB["Application Load Balancer<br/>HTTP :80 · created by AWS Load Balancer Controller"]
                NAT["NAT gateways<br/>one per AZ"]
            end

            subgraph Private["Private subnets"]
                EKSAPI["Amazon EKS control plane<br/>private API endpoint only"]
                Nodes["Managed EC2 node group<br/>2 desired · 2–6 autoscaled"]
                SSMHost["Private SSM administration host<br/>no public IP or inbound rules"]
                KubeSystem["kube-system<br/>AWS Load Balancer Controller"]
                App["swordhealth namespace<br/>node-example · 2 replicas<br/>NodePort :30080"]
            end

            subgraph Database["Isolated database subnets"]
                RDS["Private encrypted Amazon RDS for MySQL<br/>not publicly accessible"]
                RestoreTest["Temporary restore-test database<br/>created by AWS Backup"]
            end

            EndpointSet["VPC endpoints<br/>S3 gateway · ECR · STS · SSM · EKS · SQS · CloudWatch Logs"]
        end

        Buckets["Private S3 buckets<br/>read: ListBucket + GetObject<br/>write: PutObject"]
        Queue["Encrypted SQS queue"]
        Backup["AWS Backup vault and plan<br/>daily recovery points · weekly restore tests"]
        Secrets["AWS Secrets Manager<br/>RDS-managed master credentials"]
        Logs["CloudWatch Logs<br/>EKS control-plane logs"]
        OIDC["GitHub OIDC plan/apply roles"]
        State["Encrypted, versioned S3 Terraform state"]
    end

    Argo["Argo CD<br/>private ClusterIP service"]
    RootApp["Argo CD root Application<br/>delivery project and child Applications"]

    Operator -->|"SSO + SSM port-forward"| SSMHost
    SSMHost -->|"private HTTPS :443"| EKSAPI
    Operator -->|"kubectl via local tunnel"| EKSAPI
    PlatformAccess["EKS access entries<br/>platform/admin-host: cluster admin<br/>optional roles: namespace-scoped edit"]
    PlatformAccess -.-> EKSAPI

    Internet -->|"HTTP :80"| ALB
    KubeSystem -->|"Ingress creates and configures"| ALB
    ALB -->|"instance targets / NodePort :30080<br/>NetworkPolicy allows ALB subnet CIDRs"| App
    Nodes --- KubeSystem
    Nodes --- App

    App -.->|"EKS Pod Identity<br/>List/Get read bucket · Put write bucket"| Buckets
    App -.->|"EKS Pod Identity<br/>receive/delete/change visibility"| Queue
    Nodes -->|"security group permits MySQL :3306"| RDS
    RDS -->|"daily recovery points"| Backup
    Backup -->|"scheduled restore tests"| RestoreTest
    RDS -.->|"managed credentials"| Secrets
    EKSAPI --> Logs
    Nodes --> EndpointSet
    SSMHost --> EndpointSet
    Nodes -->|"general outbound egress"| NAT

    GitHubInfra -->|"OIDC; Terraform workflow"| OIDC
    OIDC -->|"state read/write"| State
    OIDC -->|"Terraform provisions AWS resources"| VPC
    OIDC -->|"Terraform provisions AWS services"| Buckets

    GitHubDelivery -->|"Argo CD polls main"| RootApp
    Operator -->|"Helm bootstrap over SSM tunnel"| Argo
    RootApp --> Argo
    Argo -->|"syncs controller and app"| KubeSystem
    Argo --> App
    App -->|"pull image"| DockerHub
```

## Ownership and deployment sequence

1. **Infrastructure repository:** Terraform provisions the VPC, subnets, gateways/endpoints, private EKS cluster and node group, SSM administration host, RDS MySQL and backup configuration, S3/SQS dependencies, workload IAM roles/Pod Identity associations, and load balancer controller IAM prerequisites.
2. **Infrastructure CI:** GitHub Actions assumes scoped plan/apply roles through GitHub OIDC. Terraform state is stored in the encrypted, versioned S3 backend. Public GitHub-hosted runners do not connect to the private Kubernetes API.
3. **Cluster access:** An authorized operator starts an SSM remote-host port-forward through the private admin host, then runs `kubectl` locally through the tunnel. The host and configured platform administrator role are cluster-admin principals. Optional namespace editor role ARNs receive access only in the configured application namespace.
4. **Delivery repository:** After the cluster is reachable, an operator runs the idempotent Helm bootstrap for Argo CD. Argo CD then reads the delivery repository's `main` branch and reconciles the AWS Load Balancer Controller and the application.
5. **Application traffic:** The controller creates an internet-facing HTTP ALB from the Ingress. The ALB forwards to worker-node NodePort `30080`; the application NetworkPolicy allows ingress only from the configured public ALB subnet CIDRs. HTTPS requires a domain and ACM certificate configuration.

## Important boundaries

- The EKS API is private; the public ALB exposes only the application endpoint, not Kubernetes or Argo CD.
- Argo CD is installed by the delivery repository's Helm bootstrap, not by the Terraform environment root. It is a private `ClusterIP` service.
- The application service account receives scoped S3 and SQS permissions through EKS Pod Identity. The sample image does not itself connect to the provisioned database, buckets, or queue.
- The RDS security group allows MySQL from the EKS node security group. This is network reachability, not proof that the sample application uses the database.
- AWS Backup is configured for daily backups and weekly restore testing; a successful restore should be verified from AWS Backup recovery/test results before claiming recovery has been demonstrated.
- Production values shown here are environment-specific. The Terraform modules and environment inputs are reusable, but delivery repo cluster/VPC/subnet values must be supplied for each additional environment.

## Source repositories

- [Infrastructure and Terraform](https://github.com/Raymondo-hub/swordhealth-aws-eks-terraform-challenge)
- [Application delivery and GitOps](https://github.com/Raymondo-hub/swordhealth-deploy)
