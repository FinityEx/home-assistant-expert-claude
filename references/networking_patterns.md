# Home Assistant Networking Patterns Guide

**Last Updated:** 2026-02-18  
**Target Environment:** HA OS at 192.168.0.143:8123

This comprehensive guide covers networking patterns, configurations, and best practices for Home Assistant deployments with ESP32 devices, Zigbee, MQTT, and WLED.

---

## Table of Contents

1. [Reverse Proxy Setup](#reverse-proxy-setup)
2. [SSL Certificate Management](#ssl-certificate-management)
3. [VPN Integration (Tailscale/WireGuard)](#vpn-integration)
4. [MQTT Broker Setup and Security](#mqtt-broker-setup)
5. [mDNS and DNS Configuration](#mdns-and-dns-configuration)
6. [VLAN Setup for IoT Devices](#vlan-setup-for-iot-devices)
7. [Firewall Rules](#firewall-rules)
8. [Remote Access Patterns](#remote-access-patterns)

---

## 1. Reverse Proxy Setup

### Overview

Reverse proxies provide SSL termination, domain routing, and additional security layers for Home Assistant.

### 1.1 Caddy (Recommended for Beginners)

**When to Use:**
- Automatic HTTPS with Let's Encrypt
- Simplest configuration
- Built-in security headers
- Automatic HTTP/2 and HTTP/3

**Installation (Docker):**

```yaml
# docker-compose.yml
version: '3.8'
services:
  caddy:
    image: caddy:2.7-alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"  # HTTP/3
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    network_mode: host

volumes:
  caddy_data:
  caddy_config:
```

**Caddyfile Configuration:**

```caddy
# Basic setup
home.example.com {
    reverse_proxy 192.168.0.143:8123 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}

# Advanced setup with security headers
ha.example.com {
    # Automatic HTTPS via Let's Encrypt
    tls your-email@example.com

    # Security headers
    header {
        # Enable HSTS
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        # Prevent clickjacking
        X-Frame-Options "SAMEORIGIN"
        # XSS Protection
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        # CSP for HA
        Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: wss: https:"
    }

    # Rate limiting
    rate_limit {
        zone static {
            key {remote_host}
            events 100
            window 1m
        }
    }

    reverse_proxy 192.168.0.143:8123 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
        
        # WebSocket support
        transport http {
            versions h1.1 h2c
        }
    }

    # Logging
    log {
        output file /var/log/caddy/ha.log
        level INFO
    }
}
```

**Home Assistant Configuration:**

```yaml
# configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.0.0/24
    - 172.17.0.0/16  # Docker network
  ip_ban_enabled: true
  login_attempts_threshold: 5
```

### 1.2 Nginx

**When to Use:**
- Maximum performance and control
- Complex routing requirements
- Existing Nginx infrastructure
- Advanced caching needs

**Installation (Add-on):**

Install "Nginx Proxy Manager" add-on or use Docker:

```yaml
# docker-compose.yml
version: '3.8'
services:
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-ha
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
      - nginx_logs:/var/log/nginx
    network_mode: host

volumes:
  nginx_logs:
```

**Nginx Configuration:**

```nginx
# nginx.conf
http {
    # Rate limiting zone
    limit_req_zone $binary_remote_addr zone=ha_limit:10m rate=10r/s;
    
    # Upstream definition
    upstream homeassistant {
        server 192.168.0.143:8123;
        keepalive 32;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name ha.example.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name ha.example.com;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Rate limiting
        limit_req zone=ha_limit burst=20 nodelay;

        # Proxy settings
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;
        proxy_read_timeout 86400;

        location / {
            proxy_pass http://homeassistant;
        }

        # Optional: Separate location for API
        location /api/websocket {
            proxy_pass http://homeassistant/api/websocket;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # Access logs
        access_log /var/log/nginx/ha_access.log;
        error_log /var/log/nginx/ha_error.log;
    }
}
```

### 1.3 Traefik

**When to Use:**
- Docker-heavy environment
- Automatic service discovery
- Multiple services/containers
- Dynamic routing needs

**Docker Compose Setup:**

```yaml
# docker-compose.yml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    environment:
      - CF_API_EMAIL=your-email@example.com
      - CF_API_KEY=your-cloudflare-api-key
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./dynamic.yml:/dynamic.yml:ro
      - ./acme.json:/acme.json
      - traefik_logs:/logs
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`traefik.example.com`)"
      - "traefik.http.routers.dashboard.service=api@internal"

volumes:
  traefik_logs:
```

**Traefik Configuration:**

```yaml
# traefik.yml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    exposedByDefault: false
  file:
    filename: /dynamic.yml

log:
  level: INFO
  filePath: /logs/traefik.log

accessLog:
  filePath: /logs/access.log
```

```yaml
# dynamic.yml
http:
  routers:
    homeassistant:
      rule: "Host(`ha.example.com`)"
      service: homeassistant
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      middlewares:
        - ha-headers
        - ha-ratelimit

  services:
    homeassistant:
      loadBalancer:
        servers:
          - url: "http://192.168.0.143:8123"
        passHostHeader: true

  middlewares:
    ha-headers:
      headers:
        sslRedirect: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        forceSTSHeader: true
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        customFrameOptionsValue: "SAMEORIGIN"

    ha-ratelimit:
      rateLimit:
        average: 100
        burst: 50
```

---

## 2. SSL Certificate Management

### 2.1 Let's Encrypt with DuckDNS

**When to Use:**
- Free SSL certificates
- Dynamic IP address
- No static IP or domain registrar access

**Setup with Duck DNS Add-on:**

1. Install "Duck DNS" add-on
2. Configure:

```yaml
# Duck DNS add-on configuration
lets_encrypt:
  accept_terms: true
  algo: secp384r1
  certfile: fullchain.pem
  keyfile: privkey.pem
token: YOUR_DUCKDNS_TOKEN
domains:
  - yourdomain.duckdns.org
aliases: []
seconds: 300
```

3. Home Assistant configuration:

```yaml
# configuration.yaml
http:
  ssl_certificate: /ssl/fullchain.pem
  ssl_key: /ssl/privkey.pem
  server_host:
    - 0.0.0.0
    - '::'
  cors_allowed_origins:
    - https://yourdomain.duckdns.org
```

### 2.2 Let's Encrypt with Certbot

**Manual Certificate Generation:**

```bash
# Install certbot
apt-get update
apt-get install certbot

# Generate certificate (HTTP challenge)
certbot certonly --standalone \
  --preferred-challenges http \
  --email your-email@example.com \
  --agree-tos \
  -d ha.example.com

# Or DNS challenge (for wildcards)
certbot certonly --manual \
  --preferred-challenges dns \
  --email your-email@example.com \
  --agree-tos \
  -d "*.example.com" \
  -d example.com

# Auto-renewal script
cat > /etc/cron.daily/certbot-renew << 'EOF'
#!/bin/bash
certbot renew --quiet --deploy-hook "docker restart caddy"
EOF
chmod +x /etc/cron.daily/certbot-renew
```

### 2.3 Custom CA (Self-Signed)

**When to Use:**
- Internal network only
- Testing environments
- Air-gapped systems

**Generate Self-Signed Certificate:**

```bash
# Create CA key and certificate
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -out ca.crt -subj "/CN=Home Assistant CA"

# Create server key
openssl genrsa -out server.key 2048

# Create CSR
openssl req -new -key server.key -out server.csr \
  -subj "/CN=homeassistant.local"

# Create SAN configuration
cat > san.cnf << EOF
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = homeassistant.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = homeassistant.local
DNS.2 = ha.local
IP.1 = 192.168.0.143
EOF

# Sign certificate
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 365 -sha256 \
  -extfile san.cnf -extensions v3_req

# Install on HA
mkdir -p /ssl
cp server.crt /ssl/fullchain.pem
cp server.key /ssl/privkey.pem
```

---

## 3. VPN Integration

### 3.1 Tailscale Integration

**When to Use:**
- Zero-config VPN
- Multiple remote users
- Cross-platform access
- No port forwarding

**Installation (HA OS Add-on):**

1. Install "Tailscale" add-on
2. Configure:

```yaml
# Tailscale add-on configuration
accept_dns: false
tags:
  - tag:homeassistant
userspace_networking: false
login_server: https://controlplane.tailscale.com
```

3. Start and authenticate via logs URL

**Home Assistant Configuration:**

```yaml
# configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 100.64.0.0/10  # Tailscale CGNAT range
    - 192.168.0.0/24
```

**Tailscale ACL Configuration:**

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:family"],
      "dst": ["tag:homeassistant:8123"]
    },
    {
      "action": "accept",
      "src": ["tag:homeassistant"],
      "dst": ["tag:iot:*"]
    }
  ],
  "tagOwners": {
    "tag:homeassistant": ["your-email@example.com"],
    "tag:iot": ["your-email@example.com"]
  }
}
```

**Performance Considerations:**
- Direct connections preferred (DERP as fallback)
- Enable MagicDNS for easy naming
- Use subnet routes for IoT device access
- Latency: typically <10ms on direct connections

### 3.2 WireGuard

**When to Use:**
- Maximum performance
- Self-hosted VPN
- Advanced routing control
- Corporate/enterprise use

**Server Setup (Separate Host):**

```bash
# Install WireGuard
apt-get install wireguard

# Generate keys
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Server configuration
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $(cat server_private.key)
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $(cat client_public.key)
AllowedIPs = 10.8.0.2/32
EOF

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
```

**Client Configuration:**

```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.8.0.2/32
DNS = 192.168.0.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = your-public-ip:51820
AllowedIPs = 192.168.0.0/24, 10.8.0.0/24
PersistentKeepalive = 25
```

**HA Configuration:**

```yaml
# configuration.yaml
http:
  trusted_proxies:
    - 10.8.0.0/24
```

---

## 4. MQTT Broker Setup

### 4.1 Mosquitto with Authentication

**Installation (Add-on):**

Install "Mosquitto broker" add-on

**Configuration:**

```yaml
# Mosquitto add-on configuration
logins:
  - username: homeassistant
    password: YOUR_SECURE_PASSWORD_HERE
  - username: esp32_client
    password: ESP32_PASSWORD
  - username: zigbee2mqtt
    password: ZIGBEE_PASSWORD
  
customize:
  active: true
  folder: mosquitto

certfile: fullchain.pem
keyfile: privkey.pem
require_certificate: false
```

**Custom Configuration:**

```bash
# /share/mosquitto/mosquitto.conf
persistence true
persistence_location /data/

# Logging
log_dest file /share/mosquitto/mosquitto.log
log_type all
log_timestamp true

# Listeners
listener 1883
protocol mqtt

listener 8883
protocol mqtt
cafile /ssl/ca.crt
certfile /ssl/fullchain.pem
keyfile /ssl/privkey.pem
require_certificate false

listener 9001
protocol websockets

# Security
allow_anonymous false
password_file /share/mosquitto/passwd

# ACL
acl_file /share/mosquitto/acl.conf
```

### 4.2 ACL Configuration

```bash
# /share/mosquitto/acl.conf

# Home Assistant - full access
user homeassistant
topic readwrite #

# ESP32 devices - specific topics
user esp32_client
topic read homeassistant/#
topic write esp32/+/state
topic write esp32/+/availability
topic read esp32/+/command

# Zigbee2MQTT
user zigbee2mqtt
topic readwrite zigbee2mqtt/#
topic read homeassistant/#

# WLED devices
user wled_client
topic readwrite wled/#
topic read homeassistant/light/wled_+/command
topic write homeassistant/light/wled_+/state

# Guest devices (read-only sensors)
user guest_sensor
topic read homeassistant/sensor/#
```

**Password Management:**

```bash
# Create password file
mosquitto_passwd -c /share/mosquitto/passwd homeassistant
mosquitto_passwd -b /share/mosquitto/passwd esp32_client ESP32_PASSWORD
mosquitto_passwd -b /share/mosquitto/passwd zigbee2mqtt ZIGBEE_PASSWORD

# Update password
mosquitto_passwd /share/mosquitto/passwd username

# Delete user
mosquitto_passwd -D /share/mosquitto/passwd username
```

### 4.3 Home Assistant MQTT Configuration

```yaml
# configuration.yaml
mqtt:
  broker: 192.168.0.143
  port: 1883
  username: homeassistant
  password: !secret mqtt_password
  discovery: true
  birth_message:
    topic: 'homeassistant/status'
    payload: 'online'
    qos: 1
    retain: true
  will_message:
    topic: 'homeassistant/status'
    payload: 'offline'
    qos: 1
    retain: true
```

---

## 5. mDNS and DNS Configuration

### 5.1 Avahi Configuration

**Default Setup (HA OS):**

Avahi is pre-configured on HA OS. Access via:
- `homeassistant.local`
- `homeassistant:8123`

**Custom Avahi Services:**

```bash
# /etc/avahi/services/homeassistant.service
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Home Assistant on %h</name>
  <service>
    <type>_http._tcp</type>
    <port>8123</port>
    <txt-record>path=/</txt-record>
  </service>
  <service>
    <type>_homeassistant._tcp</type>
    <port>8123</port>
  </service>
</service-group>
```

### 5.2 Local DNS with Pi-hole

**When to Use:**
- Ad blocking
- Custom local domains
- DNS-based device tracking
- Network-wide DNS control

**Setup:**

```bash
# Install Pi-hole
curl -sSL https://install.pi-hole.net | bash

# Custom DNS entries
echo "192.168.0.143 ha.home" >> /etc/pihole/custom.list
echo "192.168.0.143 homeassistant.home" >> /etc/pihole/custom.list

# Restart DNS
pihole restartdns
```

**HA Integration:**

```yaml
# configuration.yaml
pi_hole:
  - host: 192.168.0.1
    api_key: YOUR_API_KEY
```

### 5.3 Split DNS for VPN

**Scenario:** Different DNS resolution for VPN clients

**Unbound Configuration:**

```conf
# /etc/unbound/unbound.conf
server:
  interface: 0.0.0.0
  access-control: 192.168.0.0/24 allow
  access-control: 10.8.0.0/24 allow

  # Local zones
  local-zone: "home." static
  local-data: "ha.home. IN A 192.168.0.143"
  local-data: "mqtt.home. IN A 192.168.0.143"

  # Forward to Pi-hole for clients
  forward-zone:
    name: "."
    forward-addr: 192.168.0.1
```

---

## 6. VLAN Setup for IoT Devices

### 6.1 Network Segmentation Strategy

**Recommended VLANs:**

- VLAN 1: Management (192.168.1.0/24) - HA, router, switches
- VLAN 10: Trusted (192.168.10.0/24) - computers, phones
- VLAN 20: IoT (192.168.20.0/24) - ESP32, WLED, sensors
- VLAN 30: Guest (192.168.30.0/24) - guest WiFi
- VLAN 40: Cameras (192.168.40.0/24) - IP cameras

### 6.2 Switch Configuration (Example: UniFi)

**VLAN Setup:**

1. Create VLANs:
   - Settings → Networks → Create New Network
   - Name: IoT, VLAN ID: 20, Gateway: 192.168.20.1/24

2. WiFi Networks:
   - Create "IoT" WiFi network on VLAN 20
   - WPA2 only for compatibility
   - Disable multicast enhancement for mDNS

### 6.3 Firewall Rules for VLAN Isolation

**Firewall Rules (UniFi/pfSense):**

```
# Allow IoT → HA
Rule 1: ALLOW
  Source: IoT VLAN (192.168.20.0/24)
  Destination: HA (192.168.0.143)
  Port: 8123
  Protocol: TCP

# Allow IoT → MQTT
Rule 2: ALLOW
  Source: IoT VLAN (192.168.20.0/24)
  Destination: HA (192.168.0.143)
  Port: 1883
  Protocol: TCP

# Allow mDNS for discovery
Rule 3: ALLOW
  Source: IoT VLAN
  Destination: 224.0.0.251
  Port: 5353
  Protocol: UDP

# Allow DNS
Rule 4: ALLOW
  Source: IoT VLAN
  Destination: 192.168.0.1
  Port: 53
  Protocol: TCP/UDP

# Block IoT → Everything else
Rule 5: BLOCK
  Source: IoT VLAN
  Destination: Any
  Protocol: Any
  Log: Yes

# Allow HA → IoT (for control)
Rule 6: ALLOW
  Source: HA (192.168.0.143)
  Destination: IoT VLAN
  Protocol: Any
```

**pfSense Configuration:**

```
# Firewall → Rules → IoT

# Anti-Lockout
Pass    *    IoT net    *    *    HA (192.168.0.143)    8123

# MQTT Access
Pass    TCP    IoT net    *    HA (192.168.0.143)    1883

# mDNS
Pass    UDP    IoT net    *    224.0.0.251    5353

# DNS
Pass    *    IoT net    *    Router    53

# Block All
Block   *    IoT net    *    *    *    Log
```

### 6.4 mDNS Reflection

**Enable Cross-VLAN mDNS (Avahi):**

```bash
# /etc/avahi/avahi-daemon.conf
[server]
enable-reflector=yes
reflect-ipv=yes

[reflector]
enable-reflector=yes
```

**UniFi Controller:**

Settings → Networks → IoT → Enable Multicast DNS

---

## 7. Firewall Rules

### 7.1 Essential Ports for HA

**Required Ports:**

| Port | Protocol | Service | Exposure |
|------|----------|---------|----------|
| 8123 | TCP | HA Web UI | Internal Only |
| 443 | TCP | HTTPS (Reverse Proxy) | External (Optional) |
| 1883 | TCP | MQTT | Internal Only |
| 8883 | TCP | MQTT over SSL | Internal Only |
| 5353 | UDP | mDNS | Internal Only |
| 21063 | TCP | HomeKit | Internal Only |
| 51827 | TCP | HomeKit (Remote) | Via Proxy |

**Optional Ports:**

| Port | Protocol | Service | Notes |
|------|----------|---------|-------|
| 6052 | TCP | ESPHome | Development only |
| 3702 | UDP | WLED Discovery | LAN only |
| 51820 | UDP | WireGuard | External |
| 22 | TCP | SSH | External (key-only) |

### 7.2 iptables Configuration

**Basic iptables Rules:**

```bash
#!/bin/bash
# /etc/iptables/rules.sh

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow from local network
iptables -A INPUT -s 192.168.0.0/24 -j ACCEPT

# Allow SSH (with rate limiting)
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow mDNS
iptables -A INPUT -p udp --dport 5353 -j ACCEPT

# Allow ping (rate limited)
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# Log dropped packets
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-dropped: "

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### 7.3 UFW Configuration (Simplified)

```bash
# Reset UFW
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow from local network
ufw allow from 192.168.0.0/24

# Allow SSH (rate limited)
ufw limit ssh

# Allow specific services
ufw allow 8123/tcp comment 'Home Assistant'
ufw allow 1883/tcp comment 'MQTT'
ufw allow 5353/udp comment 'mDNS'

# Allow VPN
ufw allow 51820/udp comment 'WireGuard'

# Enable logging
ufw logging on

# Enable firewall
ufw enable
```

---

## 8. Remote Access Patterns

### 8.1 Nabu Casa Cloud

**When to Use:**
- Easiest setup (zero config)
- Support HA development
- Want voice assistant integration
- Need reliable remote access

**Pros:**
- No port forwarding required
- Automatic SSL
- Alexa/Google Assistant integration
- WebRTC for camera streaming
- Support team included

**Cons:**
- Monthly subscription ($6.50/month, 2026 pricing)
- Data routed through cloud
- Requires internet connection

**Setup:**

```yaml
# configuration.yaml
cloud:
  alexa:
    filter:
      include_domains:
        - light
        - switch
        - climate
  google_actions:
    filter:
      include_domains:
        - light
        - switch
```

**Performance:**
- Latency: 50-150ms additional
- Bandwidth: Minimal (commands only)
- Cameras: Direct WebRTC when possible

### 8.2 Self-Hosted with DuckDNS

**When to Use:**
- Cost-conscious
- Dynamic IP
- Full control
- Learning opportunity

**Setup Steps:**

1. **Get DuckDNS domain:** yourdomain.duckdns.org
2. **Install Duck DNS add-on**
3. **Configure port forwarding:** 443 → 192.168.0.143:8123
4. **Setup reverse proxy** (see Section 1)

**Pros:**
- Free
- Full control
- Direct connection
- Lower latency

**Cons:**
- Port forwarding required
- Maintenance overhead
- Exposes IP address
- No voice assistant integration

### 8.3 VPN-Only Access (Most Secure)

**When to Use:**
- Maximum security
- No external exposure
- Technical users only
- Corporate/sensitive environments

**Setup:**
- Install Tailscale or WireGuard (see Section 3)
- No port forwarding
- Access via VPN only

**Pros:**
- No exposed services
- Encrypted tunnel
- Access to all devices
- Most secure option

**Cons:**
- VPN required on all devices
- More complex for family
- Initial setup complexity

### 8.4 Cloudflare Tunnel (Recommended Alternative)

**When to Use:**
- Free alternative to Nabu Casa
- Don't want port forwarding
- Want DDoS protection
- Need multiple services exposed

**Setup:**

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
dpkg -i cloudflared.deb

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create homeassistant

# Configure tunnel
cat > /etc/cloudflared/config.yml << EOF
tunnel: TUNNEL_ID
credentials-file: /root/.cloudflared/TUNNEL_ID.json

ingress:
  - hostname: ha.yourdomain.com
    service: http://192.168.0.143:8123
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

# Run as service
cloudflared service install
systemctl start cloudflared
```

**Cloudflare DNS:**
- Add CNAME: `ha` → `TUNNEL_ID.cfargotunnel.com`

**Pros:**
- Free
- No port forwarding
- DDoS protection
- Fast global network

**Cons:**
- Data routed through Cloudflare
- More complex than Nabu Casa
- Requires domain name

### 8.5 Comparison Matrix

| Feature | Nabu Casa | DuckDNS | VPN | Cloudflare |
|---------|-----------|---------|-----|------------|
| **Cost** | $6.50/mo | Free | Free | Free |
| **Setup** | Easy | Medium | Hard | Medium |
| **Security** | High | Medium | Highest | High |
| **Latency** | Medium | Low | Low | Low |
| **Port Forward** | No | Yes | No | No |
| **Voice Assistant** | Yes | No | No | No |
| **Family Friendly** | Yes | Yes | No | Yes |
| **Maintenance** | None | Low | Medium | Low |

---

## Common Issues and Solutions

### Issue 1: Can't Access HA via Reverse Proxy

**Symptoms:** 400 Bad Request or connection refused

**Solutions:**

```yaml
# Check trusted_proxies in configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.0.0/24  # Your LAN
    - 172.17.0.0/16   # Docker network
    - 100.64.0.0/10   # Tailscale (if used)

# Ensure proxy headers are set
# In Nginx:
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### Issue 2: MQTT Devices Not Connecting

**Check:**

1. Verify broker is running: `mosquitto_sub -h 192.168.0.143 -t '#' -v`
2. Test authentication: `mosquitto_pub -h 192.168.0.143 -u username -P password -t test -m "hello"`
3. Check ACL rules
4. Verify firewall allows port 1883

### Issue 3: Cross-VLAN mDNS Not Working

**Solution:**

```bash
# Enable mDNS reflector
# On router/firewall, allow UDP 5353 between VLANs

# UniFi:
# Settings → Networks → Enable Multicast DNS on each VLAN

# pfSense:
# Install avahi package
# Services → Avahi → Enable and configure interfaces
```

### Issue 4: SSL Certificate Errors

**Solutions:**

```bash
# Check certificate validity
openssl x509 -in /ssl/fullchain.pem -text -noout

# Verify private key matches
openssl rsa -in /ssl/privkey.pem -check

# Check permissions
chmod 644 /ssl/fullchain.pem
chmod 600 /ssl/privkey.pem
```

### Issue 5: WebSocket Connection Failed

**Nginx Fix:**

```nginx
location /api/websocket {
    proxy_pass http://homeassistant;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

---

## Security Best Practices

### 1. Defense in Depth

- Use multiple security layers
- Firewall + Reverse Proxy + VPN
- Regular updates
- Monitor access logs

### 2. Principle of Least Privilege

```yaml
# MQTT: Create separate users per device
# VLANs: Isolate untrusted devices
# Firewall: Allow only required ports
```

### 3. Regular Security Audits

```bash
# Check open ports
nmap -sT 192.168.0.143

# Review HA logs
grep "Login attempt" /config/home-assistant.log

# Check failed authentications
grep "authentication failed" /share/mosquitto/mosquitto.log
```

### 4. Secure Defaults

```yaml
# configuration.yaml
http:
  ip_ban_enabled: true
  login_attempts_threshold: 5
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.0.0/24

recorder:
  exclude:
    event_types:
      - call_service  # Don't log all automations
```

---

## Performance Optimization

### Database Optimization

```yaml
# configuration.yaml
recorder:
  purge_keep_days: 7
  commit_interval: 5
  exclude:
    domains:
      - automation
      - script
    entity_globs:
      - sensor.time*
```

### MQTT Optimization

```conf
# mosquitto.conf
max_connections 100
max_queued_messages 1000
message_size_limit 10485760
```

### Network Performance

- Use wired connections for critical devices (HA, router, switches)
- 5GHz WiFi for high-bandwidth devices
- 2.4GHz for ESP32 and IoT (better range)
- QoS: Prioritize HA traffic

---

## Monitoring and Maintenance

### Essential Monitoring

```yaml
# configuration.yaml
system_health:

# Monitor SSL expiration
sensor:
  - platform: cert_expiry
    host: ha.example.com
    port: 443

# Monitor MQTT
sensor:
  - platform: mqtt
    name: "MQTT Status"
    state_topic: "homeassistant/status"
```

### Log Rotation

```bash
# Prevent log file growth
find /share/mosquitto/*.log -size +100M -exec truncate -s 50M {} \;
find /config/*.log -mtime +7 -delete
```

---

## Conclusion

This guide covers comprehensive networking patterns for Home Assistant. Choose patterns based on:

- **Security requirements:** VPN-only > Nabu Casa > Self-hosted
- **Technical skill:** Nabu Casa > Cloudflare > DuckDNS > VPN
- **Cost:** DuckDNS/VPN > Cloudflare > Nabu Casa
- **Performance:** Direct connection > VPN > Cloudflare > Nabu Casa

Always prioritize security over convenience, use VLANs to isolate IoT devices, and maintain regular backups of configurations.

**For your environment (192.168.0.143:8123):**
1. Set up VLANs for ESP32 devices
2. Install Mosquitto with ACLs
3. Consider Tailscale for remote access
4. Use Caddy for reverse proxy if needed
5. Monitor certificate expiration

**Next Steps:**
- Implement VLAN segmentation
- Set up MQTT authentication
- Configure firewall rules
- Choose remote access method
- Set up monitoring
