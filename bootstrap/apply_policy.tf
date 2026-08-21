# Least-privilege permissions for the GitHub Actions apply role.
#
# Split across five inline policies so the statements that genuinely require
# Resource = "*" are isolated in one resource. Checkov suppressions only take
# effect at the resource block level, so isolating them keeps the scoped
# policies fully covered by the scanner.

locals {
  apply_region     = "ca-central-1"
  apply_account_id = data.aws_caller_identity.current.account_id
  apply_prefix     = "devsecops-lab"

  ec2_arn_base = "arn:aws:ec2:${local.apply_region}:${local.apply_account_id}"

  # EC2 resource types the network layer creates or mutates
  ec2_network_resources = [
    "${local.ec2_arn_base}:vpc/*",
    "${local.ec2_arn_base}:subnet/*",
    "${local.ec2_arn_base}:route-table/*",
    "${local.ec2_arn_base}:internet-gateway/*",
    "${local.ec2_arn_base}:security-group/*",
    "${local.ec2_arn_base}:security-group-rule/*",
    "${local.ec2_arn_base}:vpc-endpoint/*",
    "${local.ec2_arn_base}:prefix-list/*",
    "${local.ec2_arn_base}:vpc-flow-log/*",
    "${local.ec2_arn_base}:network-interface/*",
  ]

  # EC2 resource types RunInstances touches. The AMI and its backing snapshot
  # are Amazon-owned, so those ARNs carry an empty account field.
  ec2_instance_resources = [
    "${local.ec2_arn_base}:instance/*",
    "${local.ec2_arn_base}:volume/*",
    "${local.ec2_arn_base}:network-interface/*",
    "${local.ec2_arn_base}:security-group/*",
    "${local.ec2_arn_base}:subnet/*",
    "arn:aws:ec2:${local.apply_region}::image/*",
    "arn:aws:ec2:${local.apply_region}::snapshot/*",
  ]

  elb_resources = [
    "arn:aws:elasticloadbalancing:${local.apply_region}:${local.apply_account_id}:loadbalancer/app/${local.apply_prefix}-*/*",
    "arn:aws:elasticloadbalancing:${local.apply_region}:${local.apply_account_id}:targetgroup/${local.apply_prefix}-*/*",
    "arn:aws:elasticloadbalancing:${local.apply_region}:${local.apply_account_id}:listener/app/${local.apply_prefix}-*/*/*",
  ]

  waf_acl_arn          = "arn:aws:wafv2:${local.apply_region}:${local.apply_account_id}:regional/webacl/${local.apply_prefix}-*/*"
  waf_managed_rule_arn = "arn:aws:wafv2:${local.apply_region}:${local.apply_account_id}:regional/managedruleset/*/*"

  # Both the bare and the ":*" form: log group actions split between the two
  log_group_arns = [
    "arn:aws:logs:${local.apply_region}:${local.apply_account_id}:log-group:/aws/vpc/${local.apply_prefix}-*",
    "arn:aws:logs:${local.apply_region}:${local.apply_account_id}:log-group:/aws/vpc/${local.apply_prefix}-*:*",
    "arn:aws:logs:${local.apply_region}:${local.apply_account_id}:log-group:aws-waf-logs-${local.apply_prefix}*",
    "arn:aws:logs:${local.apply_region}:${local.apply_account_id}:log-group:aws-waf-logs-${local.apply_prefix}*:*",
  ]

  alb_log_bucket_arn = "arn:aws:s3:::${local.apply_prefix}-alb-logs-${local.apply_account_id}"

  iam_scoped_resources = [
    "arn:aws:iam::${local.apply_account_id}:role/${local.apply_prefix}-*",
    "arn:aws:iam::${local.apply_account_id}:instance-profile/${local.apply_prefix}-*",
  ]
}

# Statements whose actions do not support resource-level permissions in IAM.
# Isolated here so the Checkov suppressions cover only these actions.
resource "aws_iam_role_policy" "apply_global_read" {
  # checkov:skip=CKV_AWS_355: Describe/List APIs and the CloudWatch Logs delivery APIs do not support resource-level permissions; AWS mandates Resource = "*"
  # checkov:skip=CKV_AWS_290: Same, the log-delivery write actions below are not restrictable by ARN
  # checkov:skip=CKV_AWS_289: logs:PutResourcePolicy is required by WAF logging and accepts no resource ARN
  # checkov:skip=CKV_AWS_287: No credentials-exposure actions are granted here; the wildcard is on non-restrictable read/delivery APIs only
  name = "terraform-apply-global-read"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read-only. Every Describe/List API below rejects resource-level
        # permissions, so Resource = "*" is the only accepted value.
        Sid    = "NonRestrictableReads"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:GetSecurityGroupsForVpc",
          "elasticloadbalancing:Describe*",
          "wafv2:ListWebACLs",
          "wafv2:ListAvailableManagedRuleGroups",
          "wafv2:DescribeManagedRuleGroup",
          "wafv2:GetWebACLForResource",
          "logs:DescribeLogGroups",
          "logs:DescribeResourcePolicies",
          "logs:ListLogDeliveries",
          "logs:GetLogDelivery"
        ]
        Resource = "*"
      },
      {
        # WAF logging to CloudWatch Logs goes through the log-delivery service.
        # None of these actions accept a resource ARN.
        Sid    = "LogDeliveryManagement"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:PutResourcePolicy",
          "logs:DeleteResourcePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Network and compute: VPC, subnets, routing, security groups, endpoints,
# flow logs and the EC2 instances.
resource "aws_iam_role_policy" "apply_network_compute" {
  name = "terraform-apply-network-compute"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "VpcAndNetworking"
        Effect   = "Allow"
        Resource = local.ec2_network_resources
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:ModifySecurityGroupRules",
          "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
          "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
          "ec2:CreateVpcEndpoint",
          "ec2:ModifyVpcEndpoint",
          "ec2:DeleteVpcEndpoints",
          "ec2:CreateFlowLogs",
          "ec2:DeleteFlowLogs"
        ]
      },
      {
        # StopInstances/StartInstances are required because the provider
        # applies a user_data change in place: stop, modify, start.
        Sid      = "Instances"
        Effect   = "Allow"
        Resource = local.ec2_instance_resources
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyInstanceMetadataOptions",
          "ec2:AssociateIamInstanceProfile",
          "ec2:DisassociateIamInstanceProfile",
          "ec2:ReplaceIamInstanceProfileAssociation"
        ]
      },
      {
        # Covers both tag-on-create (TagSpecifications) and the default_tags
        # applied to every resource in the stack.
        Sid      = "Tagging"
        Effect   = "Allow"
        Resource = concat(local.ec2_network_resources, local.ec2_instance_resources)
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
      },
      {
        # Public SSM parameter holding the Amazon Linux 2023 arm64 AMI id.
        # Public parameters are AWS-owned, hence the empty account field.
        Sid      = "SsmParameterRead"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${local.apply_region}::parameter/aws/service/*"
      }
    ]
  })
}

# Edge: ALB, target group, listener and the regional Web ACL in front of them.
resource "aws_iam_role_policy" "apply_edge" {
  name = "terraform-apply-edge"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # SetWebAcl is what lets wafv2:AssociateWebACL attach the Web ACL to
        # this ALB; the association fails without it.
        Sid      = "LoadBalancing"
        Effect   = "Allow"
        Resource = local.elb_resources
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
      },
      {
        Sid      = "WebAclManagement"
        Effect   = "Allow"
        Resource = [local.waf_acl_arn, local.waf_managed_rule_arn]
        Action = [
          "wafv2:CreateWebACL",
          "wafv2:UpdateWebACL",
          "wafv2:DeleteWebACL",
          "wafv2:GetWebACL",
          "wafv2:TagResource",
          "wafv2:UntagResource",
          "wafv2:ListTagsForResource",
          "wafv2:PutLoggingConfiguration",
          "wafv2:GetLoggingConfiguration",
          "wafv2:DeleteLoggingConfiguration"
        ]
      },
      {
        # Association is authorised against both the Web ACL and the ALB.
        Sid      = "WebAclAssociation"
        Effect   = "Allow"
        Resource = concat([local.waf_acl_arn], local.elb_resources)
        Action = [
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL"
        ]
      }
    ]
  })
}

# Logging: ALB access-log bucket plus the two CloudWatch log groups.
resource "aws_iam_role_policy" "apply_logging" {
  name = "terraform-apply-logging"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "LogGroupManagement"
        Effect   = "Allow"
        Resource = local.log_group_arns
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsForResource"
        ]
      },
      {
        # The provider reads every bucket sub-resource on refresh, so each of
        # these Get calls is on the plan/apply path for aws_s3_bucket.
        Sid      = "AlbLogBucketRead"
        Effect   = "Allow"
        Resource = local.alb_log_bucket_arn
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetBucketVersioning",
          "s3:GetBucketLogging",
          "s3:GetBucketNotification",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:ListBucketMultipartUploads"
        ]
      },
      {
        # DeleteBucketPolicy and PutBucketPublicAccessBlock also back the
        # delete paths for aws_s3_bucket_policy and the public access block.
        Sid      = "AlbLogBucketManagement"
        Effect   = "Allow"
        Resource = local.alb_log_bucket_arn
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketTagging",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketPublicAccessBlock"
        ]
      },
      {
        # force_destroy = true: destroy empties the bucket before deleting it.
        Sid      = "AlbLogObjectPurge"
        Effect   = "Allow"
        Resource = "${local.alb_log_bucket_arn}/*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
      }
    ]
  })
}

# IAM: the SSM instance role and profile, and the flow-log delivery role.
# Everything is confined to the project's devsecops-lab-* name prefix.
resource "aws_iam_role_policy" "apply_iam" {
  name = "terraform-apply-iam"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ScopedIamManagement"
        Effect   = "Allow"
        Resource = local.iam_scoped_resources
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]
      },
      {
        # Only the SSM managed policy may be attached. Without this condition
        # the role could attach AdministratorAccess to a role it can then pass
        # to EC2, which is a straight privilege escalation path.
        Sid      = "ScopedManagedPolicyAttachment"
        Effect   = "Allow"
        Resource = local.iam_scoped_resources
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
          }
        }
      },
      {
        # PassRole is limited to the two services in the stack that consume a
        # role: EC2 (instance profile) and VPC flow log delivery.
        Sid      = "ScopedPassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${local.apply_account_id}:role/${local.apply_prefix}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "vpc-flow-logs.amazonaws.com"
            ]
          }
        }
      },
      {
        # ELB and WAF logging each create a service-linked role on first use in
        # an account. The condition means no other service-linked role can be
        # created by this role.
        Sid      = "ServiceLinkedRoles"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "arn:aws:iam::${local.apply_account_id}:role/aws-service-role/*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "elasticloadbalancing.amazonaws.com",
              "wafv2.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# apply state role: read, write, delete access to the state bucket.
# The object statement also covers the .tflock object used by use_lockfile.
resource "aws_iam_role_policy" "apply_state" {
  name = "terraform-apply-state"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateBucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketVersioning"]
        Resource = aws_s3_bucket.tfstate.arn
      },
      {
        Sid      = "StateObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.tfstate.arn}/*"
      }
    ]
  })
}
