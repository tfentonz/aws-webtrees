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

variable "master_username" {
  default = "admin"
}

variable "master_password" {
  default = "adminpassword"
}

/* Data Sources */

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
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

data "template_file" "user_data" {
  template = file("templates/user_data.sh")
  vars = {
    region                   = var.region
    ec2_cloudwatch_parameter = aws_ssm_parameter.ec2_cloudwatch_parameter.name
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

resource "aws_security_group" "webtrees_aurora" {
  name        = "webtrees_aurora"
  description = "Access to the Aurora MySQL cluster"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "webtrees-aurora"
  }
}

resource "aws_security_group_rule" "webtrees_aurora_rule_mysql" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.webtrees.id
  security_group_id        = aws_security_group.webtrees_aurora.id
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
  user_data              = data.template_file.user_data.rendered

  tags = {
    Name = "webtrees"
  }
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.webtrees.id
}

resource "aws_iam_role" "ec2_role" {
  name_prefix        = "EC2Role"
  assume_role_policy = data.aws_iam_policy_document.ec2_role_policy.json
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  path = "/"
  role = aws_iam_role.ec2_role.name
}

resource "aws_cloudwatch_log_group" "messages" {
  name              = "webtrees-/var/log/messages"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "error_log" {
  name              = "webtrees-apache2/logs/error_log"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "access_log" {
  name              = "webtrees-apache2/logs/access_log"
  retention_in_days = 14
}

resource "aws_ssm_parameter" "ec2_cloudwatch_parameter" {
  name        = "AmazonCloudWatch-webtrees"
  type        = "String"
  description = "EC2"
  value       = file("files/ec2_cloudwatch_parameter.json")
}

resource "aws_rds_cluster" "webtrees" {
  count                        = 1
  availability_zones           = data.aws_availability_zones.available.names
  engine                       = "aurora"
  engine_version               = "5.6.10a"
  engine_mode                  = "serverless"
  cluster_identifier           = "webtrees-aurora-cluster"
  master_username              = var.master_username
  master_password              = var.master_password
  vpc_security_group_ids       = [aws_security_group.webtrees_aurora.id]
  database_name                = "webtrees"
  backup_retention_period      = 35
  storage_encrypted            = true
  deletion_protection          = true
  preferred_backup_window      = "16:03-18:03"
  preferred_maintenance_window = "tue:14:03-tue:14:33"

  scaling_configuration {
    min_capacity             = 1
    max_capacity             = 1
    auto_pause               = true
    seconds_until_auto_pause = 300
    timeout_action           = "RollbackCapacityChange"
  }
}


/* Outputs */

output "ip" {
  value = aws_eip.ip.public_ip
}

output "setup_wizard_url" {
  value = "http://${aws_eip.ip.public_ip}/webtrees"
}
