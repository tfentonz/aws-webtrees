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

    ```ssh-config
    Host webtrees
      HostName <ec2_elastic_ip>
      User bitnami
      IdentityFile ~/.ssh/webtrees
      IdentitiesOnly yes
    ```

8. Connect to the application through SSH `ssh webtrees`
9. Run the following command to see your application credentials:
  `cat ./bitnami_credentials`
10. Connect to MySQL as admin using the application credentials for password:
  `mysql --host=<RDS_CLUSTER_ENDPOINT> --port=3306 --user=admin --password`
11. Create a MySQL database, user, and grant privileges

    ```sql
    CREATE DATABASE webtrees;
    CREATE USER 'webtrees'@'%' IDENTIFIED BY '<good_secret>';
    GRANT ALL PRIVILEGES ON webtrees.* TO 'webtrees'@'%';
    \q
    ```

12. Open webtrees wizard <http://EC2\_ELASTIC\_IP/webtrees/>

## Start or Stop Services

`sudo /opt/bitnami/ctlscript.sh status`

Restart Apache

`sudo /opt/bitnami/ctlscript.sh restart apache`

## Modules

```bash
cd /opt/bitnami/apps/webtrees/htdocs
composer require magicsunday/webtrees-fan-chart --update-no-dev
```

## Update IP address

The EC2 security group allows access from your current IP address. If this
changes the ingress rules will need to be updated.

Edit `terraform.tfvars` with new IP address.

```bash
terraform plan \
  -target=aws_security_group_rule.webtrees_rule_http \
  -target=aws_security_group_rule.webtrees_rule_ssh \
  -out=$(date +plan-%Y%m%d%H%M%S)`
```

Copy and paste the terraform apply command.

```bash
terraform apply "plan-20200102030405"
```

## Uninstall

1. Run `terraform destroy`. Enter `yes` at the prompt.

## Terraform documentation

### Data Sources

* [template\_file](https://www.terraform.io/docs/providers/template/d/file.html)

### Provider Data Sources

* [aws\_availability\_zones](https://www.terraform.io/docs/providers/aws/d/availability_zones.html)

### Backup Resources

* [aws\_backup\_plan](https://www.terraform.io/docs/providers/aws/r/backup_plan.html)
* [aws\_backup\_selection](https://www.terraform.io/docs/providers/aws/r/backup_selection.html)
* [aws\_backup\_vault](https://www.terraform.io/docs/providers/aws/r/backup_vault.html)

### CloudWatch Resources

* [aws\_cloudwatch\_log\_group](https://www.terraform.io/docs/providers/aws/r/cloudwatch_log_group.html)

### EC2 Data

* [aws\_ami](https://www.terraform.io/docs/providers/aws/d/ami.html)

### EC2 Resources

* [aws\_eip](https://www.terraform.io/docs/providers/aws/r/eip.html)
* [aws\_instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [aws\_key\_pair](https://www.terraform.io/docs/providers/aws/r/key_pair.html)

### IAM Data

* [aws\_iam\_policy\_document](https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html)

### IAM Resources

* [aws\_iam\_instance\_profile](https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html)
* [aws\_iam\_role](https://www.terraform.io/docs/providers/aws/r/iam_role.html)
* [aws\_iam\_role\_policy\_attachment](https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html)

### RDS Resources

* [aws\_rds\_cluster](https://www.terraform.io/docs/providers/aws/r/rds_cluster.html)

### SSM Resources

* [aws\_ssm\_parameter](https://www.terraform.io/docs/providers/aws/r/ssm_parameter.html)

### VPC Data

* [aws\_vpc](https://www.terraform.io/docs/providers/aws/d/vpc.html)

### VPC Resources

* [aws\_security\_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [aws\_security\_group\_rule](https://www.terraform.io/docs/providers/aws/r/security_group_rule.html)

_[The End](https://open.spotify.com/track/5aHHf6jrqDRb1fcBmue2kn?si=uTAYlm-QTy-ZOZyC_WliVQ)_
