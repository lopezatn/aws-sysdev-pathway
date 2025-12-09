resource "aws_autoscaling_group" "sysdev_asg" {
  name             = "sysdev-asg"
  max_size         = 2
  min_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = [
    "subnet-0a3ab44f6771e1f6d"
  ]

  launch_template {
    id      = aws_launch_template.sysdev_web_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "sysdev-web-server"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.sysdev_tg.arn]
}
