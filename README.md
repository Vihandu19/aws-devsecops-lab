# DevSecOps & Cloud Infrastructure Lab

A production-grade, multi-AZ AWS infrastructure environment provisioned using modular Terraform, secured with least-privilege network segmentation, and managed via keyless CI/CD automation.

This lab demonstrates a zero-trust network design in AWS that completely avoids public internet exposure for application workloads. Compute resources reside entirely in private subnets with no attached NAT Gateway and no inbound SSH access. System management, package installation, and AWS service interactions are handled exclusively via VPC Endpoints and System Manager (SSM).

---

## Architecture Diagram

![DevSecOps Architecture Diagram](./diagram.png)


---

## AWS Well-Architected Framework Alignment

This architecture implements best practices across all six pillars of the AWS Well-Architected Framework:

### 1. Security
* **Network Segmentation:** Implements a strict three-tier security group chain where trust relationships are explicit by Security Group ID rather than broad CIDR blocks.
* **Zero Direct Internet Exposure:** EC2 instances reside in private subnets with no route to the internet and no inbound SSH rules. Administrative access is handled exclusively via Systems Manager (SSM) interface endpoints.
* **Identity & Access Management:** Authenticates CI/CD runners using GitHub OIDC federation, eliminating long-lived AWS access keys.
* **Detective Controls:** Centralizes audit logs across VPC Flow Logs, WAF logs, and ALB access logs.
* **Shift-Left Security:** Enforces automated Infrastructure as Code (IaC) security scanning via Checkov on pull requests.
* **Strict Egress Filtering:** Adheres to least privilege for outbound traffic. Instances are restricted from general internet (`0.0.0.0/0`) and can only reach required AWS services through designated VPC endpoints.

### 2. Cost Optimization
* **Designed for Ephemerality:** All infrastructure resources are fully ephemeral to ensure clean teardowns and eliminate standing costs between testing sessions.
* **Eliminated NAT Gateways:** Removes standard NAT Gateway hourly charges by routing S3 package retrieval through a free S3 Gateway Endpoint.
* **Ghost Billing Prevention:** Avoids unattached Elastic IPs and customer-managed KMS key fees by leveraging default SSE-S3 encryption.

### 3. Reliability
* **High Availability:** Distributes compute and load balancing across multiple Availability Zones (ca-central-1a and ca-central-1b).
* **Redundancy Planning:** Provisions redundant SSM VPC interface endpoints across both Availability Zones to preserve management access during single-AZ disruptions.
* **Automated Health Monitoring:** Configures ALB health checks to continuously monitor private target instances and automatically route traffic away from degraded compute.

### 4. Operational Excellence
* **Infrastructure as Code:** Provisions 100% of network, security, and compute resources via modular Terraform with remote S3 state storage and DynamoDB state locking.
* **CI/CD Automation:** Executes deployments, validation, and destruction through GitHub Actions, ensuring reproducible builds and eliminating manual configuration drift.
* **Centralized Observability:** Logs flow directly to CloudWatch and S3 with short lifecycle retention rules, paired with CloudWatch alarms to detect unhealthy target host counts.

### 5. Performance Efficiency
* **Right-Sized Compute:** Utilizes Graviton-based `t4g.nano` instances to deliver low-cost, power-efficient performance for lightweight workloads.
* **Optimized Traffic Routing:** Keeps service traffic within the private AWS backbone via VPC Endpoints, reducing latency and avoiding unnecessary cross-AZ internet routing.

### 6. Sustainability
* **On-Demand Resource Lifecycles:** Minimizes environmental footprint by running infrastructure on-demand through automated pipelines, preventing idle resources from consuming energy when not in active use.

---

## GitHub Actions & CI/CD Pipeline

The pipeline is automated using GitHub Actions with keyless OIDC authentication to AWS - no static credentials are stored. Two scoped IAM roles enforce least privilege: a read-only plan role for pull requests and an apply role restricted to manual deployments from main.

**Pull Request validation** (automatic on every PR):

```
Pull Request ──> OIDC (plan role) ──> Format & Validate ──> Checkov Scan ──> Terraform Plan ──> Plan posted as PR comment
```

**Deployment** (manual trigger via workflow_dispatch):

```
Run workflow ──> OIDC (apply role) ──> Terraform Plan ──> Terraform Apply
```

**Teardown** (manual trigger via workflow_dispatch):

```
Run workflow ──> OIDC (apply role) ──> Terraform Destroy
```

---

### Pipeline Features
* **Keyless OIDC Authentication:** Uses OpenID Connect to request temporary, short-lived AWS credentials scoped strictly to the IAM execution role.
* **Automated Security Scanning:** Runs Checkov across all `.tf` files on every pull request.
* **Plan Output in Pull Requests:** Automatically posts the output of `terraform plan` as a comment on pull requests for review before merging.

---

## Local Development Workflow

To validate, format, and test the Terraform configuration locally before pushing to GitHub:

```bash
# 1. Validate syntax
terraform validate

# 2. Format configuration recursively
terraform fmt -recursive

# 3. Run IaC security scan
checkov -d . --framework terraform

# 4. Preview infrastructure changes
terraform plan

# 5. Provision environment
terraform apply -auto-approve