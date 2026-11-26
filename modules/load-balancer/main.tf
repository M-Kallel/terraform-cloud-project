resource "aws_lb" "web" {
  name               = "${var.prefix}-alb"
  load_balancer_type = "application"
  subnets            = var.public_ids
  security_groups    = [var.alb_sg]
}
resource "aws_lb_target_group" "web" {
  name     = "${var.prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/health"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
