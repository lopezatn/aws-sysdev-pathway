resource "aws_launch_template" "sysdev_web_lt" {
  name_prefix   = "sysdev-web-"
  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t3.micro"
  key_name = "sysdev-nginx-key"

  iam_instance_profile {
    name = "sysdev-ec2-instance-profile"
  }

  vpc_security_group_ids = [
    aws_security_group.web_sg.id,
  ]

  user_data = base64encode(file("${path.module}/userdata-script.sh"))
}
