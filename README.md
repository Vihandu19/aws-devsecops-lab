# Cloud Infrastructure and DevSecOps lab

## Workflow
terraform validate
terraform fmt -recursive
checkov -d . --framework terraform
terraform plan
terraform apply


## AWS Well-Architected Framework

This architecture implements best practices across the AWS Well-Architected Framework's six pillars:

### 1. Security
*   **Network Segmentation:** Implements a security group chain where trust relationships are explicit by ID, not CIDR block.
*   **No Internet Exposure:** EC2 instances reside in private subnets with no route to the internet and no inbound SSH rules. Administrative access is handled exclusively via SSM interface endpoints.
*   **Identity & Access Management:** Uses GitHub OIDC federation instead of long-lived AWS credentials for CI/CD authentication.
*   **Detective Controls:** Account-level audit and threat detection mechanisms, including CloudTrail, GuardDuty with EventBridge/SNS alerting, VPC Flow Logs, and ALB access logs.
*   **Shift-Left Security:** Enforces mandatory automated IaC security scanning via Checkov for pull-requests.
*  **Strict Egress Filtering:** Adheres to the principle of least privilege for outbound traffic. IInstances are restricted from general internet (0.0.0.0/0) and only permitted to reach required AWS services through VPC endpoints.

### 2. Cost Optimization
*   **Designed for Ephemerality:** Fully ephemeral ensures the entire environment is destroyable. Nothing billing hourly survives a teardown (other than remote state management).
*   **Eliminated NAT Gateways:** Avoids the cost of  NAT gateways by routing package installation through a S3 gateway endpoint.
*   **Resource Pruning:** Actively avoids unattached Elastic IPs and Customer-managed KMS keys by opting for free SSE-S3 encryption to prevent post-teardown ghost billing.

### 3. Reliability
*   **High Availability:** Distributes network and compute resources across multiple AZ's through a ALB
*   **Redundancy Planning:** Explicitly places VPC interface endpoints for SSM in both availability zones to ensure administrative access survives an isolated AZ outage.
*   **Automated Health Checks:** Utilizes ALB health checks to continuously monitor the health of target instances.

### 4. Operational Excellence
*   **Infrastructure as Code:** Provisions the entire environment via Terraform and remote S3 state
*   **CI/CD Automation:** Manages deployments and teardowns entirely through GitHub Actions, ensuring reproducible builds and reducing human error.
*   **Observability:** Centralizes logging to CloudWatch and S3, utilizing CloudWatch alarms to monitor ALB unhealthy host counts and errors.

### 5. Performance Efficiency
*   **Compute Selection:** Utilizes t4g.nano instances demonstrating right-sizing for lightweight, cost-effective lab traffic.
*   **Optimized Routing:** Uses VPC endpoints and private DNS to keep AWS service traffic on the AWS network while minimizing unnecessary cross-AZ traffic.

### 6. Sustainability
*   **Resource Efficiency:** Because the lab targets low monthly runtime with ephemeral resources which are strictly spun up on demand. This prevents idle infrastructure from unnecessarily drawing energy.


## Github Actions