terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "dev"
}

# Read the Ubuntu AMI ID from SSM
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/jammy/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# Security Group for SSH + HTTP
resource "aws_security_group" "web_sg" {
  name        = "sysdev-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = "vpc-0b18e9d3e37be5edc"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "sysdev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy to allow EC2 DescribeInstances
resource "aws_iam_role_policy" "ec2_describe_instances" {
  name = "sysdev-ec2-describe-instances"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "sysdev-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web" {
  ami = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t3.micro"
  subnet_id = "subnet-0a3ab44f6771e1f6d"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = "sysdev-nginx-key"
  tags = {
    Name = "sysdev-web-server"
  }
}