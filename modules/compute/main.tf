data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}
resource "aws_launch_template" "web" {
  name_prefix            = "${var.prefix}-"
  image_id               = var.ami_id != null ? var.ami_id : data.aws_ami.linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.app_sg]
  user_data              = filebase64("${path.module}/user_data.sh")
  metadata_options {
    http_tokens = "required"
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }
}
resource "aws_autoscaling_group" "web" {
  name                      = "${var.prefix}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.app_ids
  target_group_arns         = [var.target_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
  }
  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.prefix}-web" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    precondition {
      condition     = var.min_size >= 2 && var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
      error_message = "Require 2 <= minimum <= desired <= maximum."
    }
  }
}
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.prefix}-cpu"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}
