#!/bin/bash
apt-get update -y
apt-get install -y --no-install-recommends collectd
apt-get remove -y awscli

# Install AWS CLI version 2
cd /tmp
wget -O awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip awscliv2.zip
./aws/install

# Install CloudWatch Agent
mkdir /tmp/cloudwatch && cd $_
wget https://s3.${region}.amazonaws.com/amazoncloudwatch-agent-${region}/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Install SSM Agent
mkdir /tmp/ssm && cd $_
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i -E ./amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent

# Install webtrees
cd /tmp
mkdir /opt/bitnami/apps/webtrees
wget https://github.com/fisharebest/webtrees/releases/download/2.0.3/webtrees-2.0.3.zip
unzip -d /opt/bitnami/apps/webtrees/ webtrees-2.0.3.zip
mv /opt/bitnami/apps/webtrees/webtrees/ /opt/bitnami/apps/webtrees/htdocs/
mkdir /opt/bitnami/apps/webtrees/conf/
chown -R bitnami:daemon /opt/bitnami/apps/webtrees/htdocs
chmod -R g+w /opt/bitnami/apps/webtrees/htdocs/

cat << EOF >> /opt/bitnami/apache2/conf/bitnami/bitnami-apps-prefix.conf
Include "/opt/bitnami/apps/webtrees/conf/httpd-prefix.conf"
EOF

cat << EOF > /opt/bitnami/apps/webtrees/conf/httpd-prefix.conf
Alias /webtrees/ "/opt/bitnami/apps/webtrees/htdocs/"
Alias /webtrees "/opt/bitnami/apps/webtrees/htdocs/"
Include "/opt/bitnami/apps/webtrees/conf/httpd-app.conf"
EOF

cat << EOF > /opt/bitnami/apps/webtrees/conf/httpd-app.conf
<Directory /opt/bitnami/apps/webtrees/htdocs/>
    Options +FollowSymLinks
    AllowOverride None
    <IfVersion < 2.3>
        Order allow,deny
        Allow from all
    </IfVersion>
    <IfVersion >= 2.3>
        Require all granted
    </IfVersion>
</Directory>
EOF

# Enable CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${ec2_cloudwatch_parameter} -s

# Restart Apache
/opt/bitnami/ctlscript.sh restart apache
