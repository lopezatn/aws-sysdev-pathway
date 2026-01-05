resource "aws_autoscaling_group" "sysdev_asg" {
  name             = "sysdev-asg"
  max_size         = var.max_size
  min_size         = var.min_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = data.aws_subnets.default_vpc_subnets.ids

  launch_template {
    id      = aws_launch_template.sysdev_web_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.sysdev_tg.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "sysdev-web-server"
    propagate_at_launch = true
  }

}
