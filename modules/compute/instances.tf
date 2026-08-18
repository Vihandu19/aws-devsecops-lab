data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}


resource "aws_instance" "ec2" {
  for_each = var.private_subnets

  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [var.instance_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = <<-EOF
    #!/bin/bash
    until dnf install -y nginx; do
        echo "Retrying nginx install in 10s"
        sleep 10
    done
    echo "$(hostname -f)" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "${var.name_prefix}-${each.key}"
  }
}