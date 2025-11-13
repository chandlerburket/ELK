#!/bin/bash

echo "==============================================="
echo "ELK Stack Setup for Suricata"
echo "==============================================="
echo ""

# Check if docker and docker-compose are installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi

# Set vm.max_map_count for Elasticsearch
echo "Setting vm.max_map_count for Elasticsearch..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Check if Suricata log directory exists
if [ ! -d "/var/log/suricata" ]; then
    echo "Warning: /var/log/suricata directory not found!"
    echo "Please make sure Suricata is installed and running."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Prompt for password
echo ""
echo "Please set a password for Elasticsearch (or press Enter for default 'changeme'):"
read -s password
if [ -z "$password" ]; then
    password="changeme"
fi

# Update password in all config files
echo "Updating configuration files with password..."
sed -i "s/ELASTIC_PASSWORD=changeme/ELASTIC_PASSWORD=$password/g" docker-compose.yml
sed -i "s/ELASTICSEARCH_PASSWORD=changeme/ELASTICSEARCH_PASSWORD=$password/g" docker-compose.yml
sed -i "s/password => \"changeme\"/password => \"$password\"/g" logstash/pipeline/suricata.conf
sed -i "s/xpack.monitoring.elasticsearch.password: changeme/xpack.monitoring.elasticsearch.password: $password/g" logstash/config/logstash.yml

echo ""
echo "Starting ELK stack..."
docker-compose up -d

echo ""
echo "Waiting for services to start (this may take a minute)..."
sleep 30

echo ""
echo "==============================================="
echo "Setup Complete!"
echo "==============================================="
echo ""
echo "Access Kibana at: http://$(hostname -I | awk '{print $1}'):5601"
echo "Username: elastic"
echo "Password: $password"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo ""
echo "To stop the stack:"
echo "  docker-compose down"
echo ""
echo "Next steps:"
echo "1. Open Kibana in your browser"
echo "2. Go to Management → Stack Management → Index Patterns"
echo "3. Create index pattern: suricata-*"
echo "4. Select @timestamp as time field"
echo "5. Go to Analytics → Discover to view your Suricata logs"
echo ""