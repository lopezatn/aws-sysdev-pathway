resource "aws_launch_template" "webhost_lt" {
  name_prefix   = "webhost-"
  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type
  //  key_name      = "webhost-nginx-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id,
  ]

  user_data = base64encode(file("${path.module}/userdata-script.sh"))
}
