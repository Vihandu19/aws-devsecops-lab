resource "aws_lb_target_group_attachment" "instances" {
    for_each = var.instance_ids
    
    target_group_arn = aws_lb_target_group.alb_tg.arn
    target_id = each.value
    port = 80
}