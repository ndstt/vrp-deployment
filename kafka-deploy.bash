#!/bin/bash
# deploy kafka as a service in rocky linux 10 vm

# 1 install jdk 21 (LTS)
sudo dnf update -y
sudo dnf install -y java-21-openjdk java-21-openjdk-devel policycoreutils-python-utils
java -version

# set JAVA_HOME
sudo bash -c 'cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=\$JAVA_HOME/bin:\$PATH
EOF'
source /etc/profile.d/java.sh
echo $JAVA_HOME

# install and extract kafka
wget https://dlcdn.apache.org/kafka/4.1.0/kafka_2.13-4.1.0.tgz
tar -xzf kafka_2.13-4.1.0.tgz
rm -f kafka_2.13-4.1.0.tgz

sudo mv ~/kafka_2.13-4.1.0 /opt/kafka
sudo useradd -r -M -d /opt/kafka -s /sbin/nologin kafka

sudo chown -R kafka:kafka /opt/kafka

# change log dir to /var/lib/kafka-logs
sudo mkdir -p /var/lib/kafka-logs
sudo chown -R kafka:kafka /var/lib/kafka-logs
sudo sed -i 's|^log.dirs=.*|log.dirs=/var/lib/kafka-logs|' /opt/kafka/config/server.properties

# generate cluster id and format logs
KAFKA_CLUSTER_ID="$(/opt/kafka/bin/kafka-storage.sh random-uuid)"
sudo -u kafka /opt/kafka/bin/kafka-storage.sh format --standalone -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/server.properties

# set selinux context
sudo semanage fcontext -a -t bin_t "/opt/kafka(/.*)?"
sudo restorecon -Rv /opt/kafka

# create kafka systemd service
sudo bash -c 'cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka Server
Documentation=https://kafka.apache.org/documentation/
After=network.target

[Service]
Type=simple
User=kafka
Group=kafka
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk"
Environment="PATH=/usr/lib/jvm/java-21-openjdk/bin:/usr/bin:/bin"
WorkingDirectory=/opt/kafka
ExecStartPre=/bin/sleep 5
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

# enable + start kafka
sudo systemctl daemon-reload
sudo systemctl enable kafka
sudo systemctl start kafka
sudo systemctl status kafka
