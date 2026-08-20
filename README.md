# Cloud Infrastructure and DevSecOps lab
terraform validate
checkov -d . --framework terraform


## AWS Well-Architected Framework

While designed as an ephemeral lab environment rather than a production workload, this architecture implements best practices across the AWS Well-Architected Framework's six pillars:

### 1. Security
*   **Network Segmentation:** Implements a security group chain where trust relationships are explicit by ID, not CIDR block.
*   **No Internet Exposure:** EC2 instances reside in private subnets with no route to the internet and no inbound SSH rules. Administrative access is handled exclusively via secure Systems Manager (SSM) interface endpoints.
*   **Identity & Access Management:** Completely eliminates long-lived AWS access keys through keyless GitHub OIDC federation. CI/CD roles are explicitly scoped to least-privilege permissions.
*   **Detective Controls:** Layers account-level audit and threat detection mechanisms, including CloudTrail, GuardDuty with EventBridge/SNS alerting, VPC Flow Logs, and ALB access logs.
*   **Shift-Left Security:** Enforces automated IaC security scanning via Checkov as a mandatory pull-request gate.
*  **Strict Egress Filtering:** Adheres to the principle of least privilege for outbound traffic. Instances are restricted from general internet access (0.0.0.0/0) and are explicitly permitted to route outbound HTTPS traffic solely to Systems Manager (via security group IDs) and Amazon S3 (via dynamically updated AWS Prefix Lists) for package management.

### 2. Cost Optimization
*   **Designed for Ephemerality:** A strict design constraint ensures the entire environment is destroyable. Nothing billing hourly survives a teardown, supported by a scheduled automated destroy workflow acting as a FinOps control.
*   **Eliminated NAT Gateways:** Avoids the baseline ~$66/month cost of two NAT gateways by routing package installation through a free S3 gateway endpoint.
*   **Resource Pruning:** Actively avoids unattached Elastic IPs and Customer-managed KMS keys (opting for free SSE-S3 encryption) to prevent post-teardown ghost billing.

### 3. Reliability
*   **High Availability:** Distributes network and compute resources across multiple Availability Zones, featuring a multi-AZ public load balancer.
*   **Redundancy Planning:** Explicitly places VPC interface endpoints for SSM in both availability zones to ensure administrative access survives an isolated AZ outage.
*   **Automated Health Checks:** Utilizes ALB health checks to continuously monitor the health of target instances.

### 4. Operational Excellence
*   **Infrastructure as Code:** Provisions the entire environment via modular Terraform with clean interfaces, remote S3 state, and lockfile-based state locking.
*   **CI/CD Automation:** Manages deployments and teardowns entirely through GitHub Actions, ensuring reproducible builds and reducing human error.
*   **Observability:** Centralizes logging to CloudWatch and S3, utilizing CloudWatch alarms to proactively monitor ALB unhealthy host counts and 5XX errors.

### 5. Performance Efficiency
*   **Compute Selection:** Utilizes ARM-based Graviton (`t4g.nano`) instances to demonstrate right-sizing for lightweight, cost-effective lab traffic.
*   **Optimized Routing:** Leverages private DNS for VPC interface endpoints and regional endpoint names to manage routing efficiently while controlling cross-AZ transfer costs.

### 6. Sustainability
*   **Resource Efficiency:** Because the lab targets low monthly runtime with ephemeral resources which are strictly spun up on demand. This prevents idle infrastructure from unnecessarily drawing energy.


## Github Actions