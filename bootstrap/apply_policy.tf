# resource apply role: create, modify and delete resouces
resource "aws_iam_role_policy" "apply_services" {
  name = "terraform-apply-services"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NetworkAndCompute"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:ca-central-1::parameter/aws/service/*"
      },
      {
        Sid      = "BudgetManagement"
        Effect   = "Allow"
        Action   = ["budgets:*"]
        Resource = "*"
      },
      {
        Sid    = "WAF"
        Effect = "Allow"
        Action = ["wafv2:*"]
        Resource = "*"
      }
    ]
  })
}

# IAM apply role: create, modify and delete IAM roles and instance profiles
resource "aws_iam_role_policy" "apply_iam" {
  name = "terraform-apply-iam"
  role = aws_iam_role.gha_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ScopedIamManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/devsecops-lab-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/devsecops-lab-*"
        ]
      }
    ]
  })
}

# apply state role: read, write, delete access to the state bucket
resource "aws_iam_role_policy" "apply_state" {
  name = "terraform-state-access"
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