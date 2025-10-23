#!/bin/bash
# reset kafka on rocky linux 10
# ⚠️ WARNING: this will remove all Kafka data, logs, and service state

set -e

echo "🧹 Stopping Kafka service..."
sudo systemctl stop kafka 2>/dev/null || true
sudo systemctl disable kafka 2>/dev/null || true

echo "🧨 Removing Kafka systemd service..."
sudo rm -f /etc/systemd/system/kafka.service
sudo systemctl daemon-reload

echo "🔥 Deleting Kafka directories..."
sudo rm -rf /opt/kafka
sudo rm -rf /var/lib/kafka-logs
sudo rm -rf /tmp/kraft-combined-logs

echo "👻 Deleting Kafka system user..."
if id kafka &>/dev/null; then
    sudo userdel -r kafka 2>/dev/null || true
fi

echo "🧽 Cleaning SELinux contexts..."
sudo semanage fcontext -d "/opt/kafka(/.*)?" 2>/dev/null || true
sudo semanage fcontext -d "/var/lib/kafka-logs(/.*)?" 2>/dev/null || true
sudo restorecon -Rv /opt 2>/dev/null || true
sudo restorecon -Rv /var/lib 2>/dev/null || true

echo "🚮 Cleaning leftover files..."
sudo rm -rf /etc/profile.d/java.sh 2>/dev/null || true
sudo find /tmp -maxdepth 1 -type d -name "kraft*" -exec rm -rf {} + 2>/dev/null || true

echo "✅ Kafka reset completed!"
echo "System is clean. You can now re-run your deploy script."
