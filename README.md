# aws-webtrees

Terraform configuration for [webtrees](https://webtrees.net) genealogy
application on AWS

## Overview

This Terraform configuration creates an EC2 instance in the default VPC. The
EC2 instance lauches a [Bitnami LAMP](https://bitnami.com/stack/lamp) stack AMI.

The security group allows SSH and HTTP access from a your IP address specified
in a Terraform variable.

The EC2 instance user data downloads and installs webtrees app to
`/opt/bitnami/apps/webtrees`.

## Prerequisites

* An AWS account is required
* AWS CLI profile setup and configured
* Terraform installed `brew install terraform`

## Install

1. Set up Terraform variables `cp terraform.tfvars.example terraform.tfvars`
2. Edit `terraform.tfvars` profile, region, and your public IP address.
3. Generate an SSH key `ssh-keygen -t rsa -b 2048 -f ~/.ssh/webtrees`
4. Update the permissions of that key with `chmod 400 ~/.ssh/webtrees`
5. Run Terraform plan to see changes `terraform plan`
6. Apply Terraform plan `terraform apply`. Enter `yes` at the prompt.
7. Set up the following in `~/.ssh/config` replacing `<elastic_ip>` with the
output value.

    ```
    Host webtrees
      HostName <ec2_elastic_ip>
      User bitnami
      IdentityFile ~/.ssh/webtrees
      IdentitiesOnly yes
    ```
8. Connect to the application through SSH `ssh webtrees`
9. Run the following command to see your application credentials:<br>
  `cat ./bitnami_credentials`
10. Connect to MySQL as root using the application credentials for password:<br>
  `mysql --host=localhost --port=5432 --user=root --password`
11. Create a MySQL database, user, and grant privileges

    ```
    CREATE DATABASE webtrees;
    CREATE USER 'webtrees'@'localhost' IDENTIFIED BY '<good_secret>';
    GRANT ALL PRIVILEGES ON webtrees.* TO 'webtrees'@'localhost';
    \q
    ```
12. Open webtrees wizard http://<ec2\_elastic\_ip/webtrees/

## Uninstall

1. Run `terraform destroy`. Enter `yes` at the prompt.

## Terraform documentation

### Data Sources
* [template\_file](https://www.terraform.io/docs/providers/template/d/file.html)

### CloudWatch
#### Resources
* [aws\_cloudwatch\_log\_group](https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html)

### EC2
#### Data
* [aws\_ami](https://www.terraform.io/docs/providers/aws/d/ami.html)

#### Resources
* [aws\_eip](https://www.terraform.io/docs/providers/aws/r/eip.html)
* [aws\_instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [aws\_key\_pair](https://www.terraform.io/docs/providers/aws/r/key_pair.html)

### IAM
#### Data
* [aws\_iam\_policy\_document](https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html)


#### Resources
* [aws\_iam\_instance\_profile](https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html)
* [aws\_iam\_role](https://www.terraform.io/docs/providers/aws/r/iam_role.html)
* [aws\_iam\_role\_policy\_attachment](https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html)

### SSM
#### Resources
* [aws\_ssm\_parameter](https://www.terraform.io/docs/providers/aws/r/ssm_parameter.html)

### VPC
#### Data
* [aws\_vpc](https://www.terraform.io/docs/providers/aws/d/vpc.html)

#### Resources
* [aws\_security\_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [aws\_security\_group\_rule](https://www.terraform.io/docs/providers/aws/r/security_group_rule.html)

_[The End](https://open.spotify.com/track/5aHHf6jrqDRb1fcBmue2kn?si=uTAYlm-QTy-ZOZyC_WliVQ)_

