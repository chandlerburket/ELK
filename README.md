# ELK Stack for Suricata - Docker Setup

This Docker Compose setup provides a complete ELK (Elasticsearch, Logstash, Kibana) stack for visualizing and analyzing Suricata IDS logs.

## Quick Start

1. Copy all files to your Ubuntu server (e.g., `/opt/elk-suricata/`)

2. Run the setup script:
   ```bash
   ./setup.sh
   ```

3. Access Kibana at `http://your-server-ip:5601`
   - Username: `elastic`
   - Password: (the one you set during setup)

4. Create the index pattern in Kibana:
   - Go to **Management** → **Stack Management** → **Index Patterns**
   - Click **Create index pattern**
   - Enter `suricata-*`
   - Select `@timestamp` as time field
   - Click **Create**

5. View your data:
   - Go to **Analytics** → **Discover**
   - Select the `suricata-*` index pattern

## Manual Setup

If you prefer not to use the setup script:

1. Update passwords in these files:
   - `docker-compose.yml` (ELASTIC_PASSWORD and ELASTICSEARCH_PASSWORD)
   - `logstash/pipeline/suricata.conf` (password field)
   - `logstash/config/logstash.yml` (xpack.monitoring.elasticsearch.password)

2. Set system parameter for Elasticsearch:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   ```

3. Start the stack:
   ```bash
   docker-compose up -d
   ```

## Directory Structure

```
.
├── docker-compose.yml
├── setup.sh
├── README.md
└── logstash/
    ├── config/
    │   └── logstash.yml
    └── pipeline/
        └── suricata.conf
```

## Docker Commands

Start the stack:
```bash
docker-compose up -d
```

Stop the stack:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f
docker-compose logs -f logstash  # View only Logstash logs
```

Restart a service:
```bash
docker-compose restart logstash
```

Check service status:
```bash
docker-compose ps
```

## Configuration

### Suricata Log Path
The default configuration reads from `/var/log/suricata/eve.json`. If your Suricata logs are elsewhere, update the volume mount in `docker-compose.yml`:

```yaml
volumes:
  - /your/suricata/log/path:/var/log/suricata:ro
```

### Memory Settings
Default memory allocation:
- Elasticsearch: 512MB (ES_JAVA_OPTS)
- Logstash: 256MB (LS_JAVA_OPTS)

Adjust in `docker-compose.yml` if needed for your server's resources.

### Index Pattern
Logs are indexed daily as `suricata-YYYY.MM.DD`. This allows for easy management and rotation.

## Troubleshooting

### No data in Kibana

1. Check if Suricata is generating logs:
   ```bash
   sudo tail -f /var/log/suricata/eve.json
   ```

2. Check Logstash is reading the file:
   ```bash
   docker-compose logs logstash | grep "suricata"
   ```

3. Verify Elasticsearch has data:
   ```bash
   curl -u elastic:YOUR_PASSWORD http://localhost:9200/_cat/indices?v
   ```
   You should see `suricata-*` indices.

### Elasticsearch won't start

Check if vm.max_map_count is set:
```bash
sysctl vm.max_map_count
```
Should return `262144`. If not, run:
```bash
sudo sysctl -w vm.max_map_count=262144
```

### Permission denied on Suricata logs

Ensure the logstash container can read Suricata logs:
```bash
sudo chmod 644 /var/log/suricata/eve.json
```

Or add the appropriate user permissions.

### Services keep restarting

Check logs for specific errors:
```bash
docker-compose logs elasticsearch
docker-compose logs logstash
docker-compose logs kibana
```

## Creating Visualizations

Once data is flowing:

1. Go to **Analytics** → **Visualize Library** in Kibana
2. Click **Create visualization**
3. Some useful visualizations:
   - **Alert Timeline**: Area chart with `@timestamp` and count of alerts
   - **Top Alert Signatures**: Pie chart of `alert.signature.keyword`
   - **Source/Dest Countries**: Map using `geoip_src.country_name` and `geoip_dest.country_name`
   - **Protocol Distribution**: Pie chart of `proto.keyword`
   - **Top Source IPs**: Data table of `src_ip.keyword`

4. Combine visualizations into a **Dashboard** for a complete overview

## Data Retention

By default, data is stored indefinitely. To automatically delete old indices:

1. Go to **Management** → **Stack Management** → **Index Lifecycle Policies**
2. Create a policy to delete indices older than X days
3. Apply the policy to your `suricata-*` indices

## Ports Used

- 9200: Elasticsearch API
- 5601: Kibana web interface
- 5044: Logstash Beats input (not used in this setup)
- 9600: Logstash monitoring API

## Security Notes

- Change the default password from `changeme`!
- Consider using a reverse proxy (nginx) with SSL for Kibana
- Restrict access to ports using firewall rules
- For production, enable Elasticsearch SSL/TLS

## Backup

To backup your Elasticsearch data:
```bash
docker-compose down
sudo tar -czf elk-backup-$(date +%Y%m%d).tar.gz elasticsearch-data/
docker-compose up -d
```

## Updates

To update to newer versions:

1. Update image tags in `docker-compose.yml`
2. Pull new images:
   ```bash
   docker-compose pull
   ```
3. Restart:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Resources

- Elasticsearch Docs: https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
- Kibana Docs: https://www.elastic.co/guide/en/kibana/current/index.html
- Logstash Docs: https://www.elastic.co/guide/en/logstash/current/index.html
- Suricata: https://suricata.io/

## Support

Check logs first:
```bash
docker-compose logs -f
```

For Elasticsearch/Kibana issues, check the official Elastic forums.