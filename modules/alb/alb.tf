resource "aws_lb" "alb" {
  #checkov:skip=CKV_AWS_150:Deletion protection off by design so terraform destroy works in the ephemeral lab
  #checkov:skip=CKV2_AWS_20:No HTTPS listener to redirect to; HTTP-only by design, see CKV_AWS_2
  #checkov:skip=CKV2_AWS_28:WAF is a standing monthly cost that breaks the ephemeral cost model
  name                       = "${var.name_prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  drop_invalid_header_fields = true


  security_groups = [var.alb_security_group_id]

  subnets = var.public_subnet_ids

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket = var.access_log_bucket
      enabled = true
    }
  }

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  #checkov:skip=CKV_AWS_378:HTTP-only workload by design; HTTPS requires a domain and cert, a standing cost
  name                 = "${var.name_prefix}-alb-tg"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-alb-tg"
  }
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTP-only by design; HTTPS needs a domain and ACM cert, a standing cost that breaks the ephemeral lab model
  #checkov:skip=CKV_AWS_103:No HTTPS listener to apply a TLS policy to; see CKV_AWS_2
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}