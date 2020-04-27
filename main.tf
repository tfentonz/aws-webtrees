/* Providers */

provider "aws" {
  profile = var.profile
  region  = var.region
  version = "~> 2.0"
}

/* Variables */

variable "profile" {
  default = "default"
}

variable "region" {
  default = "us-east-1"
}

variable "my_ip_cidr" {
  default = "123.45.6.78/32"
}

/* Data Sources */

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "bitnami_lampstack" {
  most_recent = true
  owners      = ["979382823631"]

  filter {
    name   = "name"
    values = ["bitnami-lampstack-7.4.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_iam_policy_document" "ec2_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

/* Resources */

resource "aws_security_group" "webtrees" {
  name        = "webtrees"
  description = "Access to the EC2 webtrees host"
  vpc_id      = data.aws_vpc.default.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webtrees-ec2-host"
  }
}

resource "aws_security_group_rule" "webtrees_rule_ssh" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [var.my_ip_cidr]
  security_group_id = aws_security_group.webtrees.id
}

resource "aws_security_group_rule" "webtrees_rule_http" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = [var.my_ip_cidr]
  security_group_id = aws_security_group.webtrees.id
}

resource "aws_key_pair" "webtrees" {
  key_name   = "webtrees"
  public_key = file("~/.ssh/webtrees.pub")
}

resource "aws_instance" "webtrees" {
  key_name               = aws_key_pair.webtrees.key_name
  ami                    = data.aws_ami.bitnami_lampstack.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.webtrees.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  monitoring             = false
  user_data              = file("user_data.sh")
  tags = {
    Name = "webtrees"
  }
}

resource "aws_iam_role" "ec2_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_role_policy.json
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  path = "/"
  role = aws_iam_role.ec2_role.name
}

resource "aws_cloudwatch_log_group" "messages" {
  name              = "webtrees-/var/log/messages"
  retention_in_days = 14
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.webtrees.id
}

/* Outputs */

output "ip" {
  value = aws_eip.ip.public_ip
}

output "setup_wizard_url" {
  value = "http://${aws_eip.ip.public_ip}/webtrees/"
}