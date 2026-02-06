########################
# Common locals
########################
locals {
alerts_topic_arn = "arn:aws:sns:eu-central-1:000000000000:webhost-alerts"
}

########################
# ALB 5XX (Load Balancer errors)
########################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "webhost-alb-5xx"
  alarm_description   = "ALB is returning 5XX errors (edge or internal)."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.webhost_alb.arn_suffix
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}

########################
# Target 5XX (your app / Nginx / instance-side errors)
########################
resource "aws_cloudwatch_metric_alarm" "tg_5xx" {
  alarm_name          = "webhost-tg-5xx"
  alarm_description   = "Targets are returning 5XX errors."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.webhost_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.webhost_tg.arn_suffix
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}

########################
# Latency (p95-like approximation needs percentile; here we use Average as a starter)
########################
resource "aws_cloudwatch_metric_alarm" "tg_latency_high" {
  alarm_name          = "webhost-tg-latency-high"
  alarm_description   = "Target response time average is high (start simple, tune later)."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = 1.5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.webhost_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.webhost_tg.arn_suffix
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}

########################
# Healthy hosts drops (best early indicator of outage behind an ALB)
########################
resource "aws_cloudwatch_metric_alarm" "tg_healthy_hosts_low" {
  alarm_name          = "webhost-tg-healthyhosts-low"
  alarm_description   = "HealthyHostCount is too low."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.webhost_alb.arn_suffix
    TargetGroup  = aws_lb_target_group.webhost_tg.arn_suffix
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}
