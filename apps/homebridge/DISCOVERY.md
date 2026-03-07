# Homebridge HomeKit Discovery Guide

## Overview

This guide explains how HomeKit discovery works on different platforms and provides platform-specific setup instructions for pairing Homebridge with Apple Home.

## How HomeKit Discovery Works

- Homebridge advertises via mDNS (Multicast DNS) on UDP port 5353
- iPhone Home app listens for these broadcasts on local network
- HomeKit communication happens over TCP port 51826 (HAP protocol)
- Both ports must be accessible for pairing and operation

## Linux & macOS Setup

### Why Discovery Works

- Native mDNS support (Avahi on Linux, Bonjour on macOS)
- Docker can map UDP 5353 without conflicts
- Multicast traffic routes between Docker and physical network

### Docker Compose Configuration

Current setup uses bridge networking with port mapping:

```yaml
ports:
  - "51826:51826"    # HomeKit HAP protocol
  - "5353:5353/udp"  # mDNS discovery (Linux/macOS only)
```

### Firewall Rules

Commands to allow mDNS and HAP traffic (if needed):

```bash
# Linux (ufw)
sudo ufw allow 51826/tcp comment 'Homebridge HAP'
sudo ufw allow 5353/udp comment 'mDNS'

# macOS
# Usually not needed - Bonjour allowed by default
```

### Troubleshooting

- Check port availability: `sudo lsof -i :5353`
- Test mDNS: `avahi-browse -rt _hap._tcp` (Linux) or `dns-sd -B _hap._tcp` (macOS)
- Verify Avahi is running: `systemctl status avahi-daemon` (Linux)

## Windows (Docker Desktop/WSL2) Setup

### Why Automatic Discovery Fails

1. **Port 5353 Conflict**: Windows Bonjour service (`mDNSResponder.exe`) already owns UDP 5353
2. **Chrome/Edge**: Browsers also bind to 5353 for their own mDNS/QUIC discovery
3. **WSL2 Networking**: Docker runs in NAT mode, isolating multicast from physical LAN
4. **Cannot Remap**: mDNS must use port 5353 - mapping to other ports (e.g., `5354:5353`) breaks discovery

### Checking Port Conflicts

```powershell
# See what's using port 5353
Get-NetUDPEndpoint -LocalPort 5353 | Select-Object OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess).Name}}

# Typical output shows:
# mDNSResponder (Apple Bonjour)
# chrome.exe
```

### Windows Firewall Configuration

Even though automatic discovery won't work, you still need port 51826 open for manual pairing:

```powershell
# Add inbound rule for Homebridge HAP (manual pairing and operation)
New-NetFirewallRule -DisplayName "Homebridge HAP" -Direction Inbound -Protocol TCP -LocalPort 51826 -Action Allow -Profile Private

# Verify rule was created
Get-NetFirewallRule -DisplayName "Homebridge HAP" | Format-Table Name, DisplayName, Enabled, Direction, Action
```

### Manual Pairing Process

Since automatic discovery doesn't work on Windows, use manual pairing:

1. **Access Homebridge UI**: `http://homebridge.${DOMAIN}` (via Traefik)
2. **Find Pairing Code**: Look for QR code and 8-digit PIN on the Homebridge dashboard
3. **Open Home App** on iPhone/iPad
4. **Add Accessory**: Tap `+` button → `Add Accessory`
5. **Manual Entry**: Tap `More options...` → `My Accessory Isn't Shown Here`
6. **Enter Code**: Type the 8-digit PIN from Homebridge UI
7. **Complete Setup**: Follow remaining prompts in Home app

**Important**: Your iPhone and Windows host must be on the same network subnet for HAP communication.

## Discovery Test Checklist

- [ ] Homebridge container is running
- [ ] Port 51826 is accessible (test with `telnet <server-ip> 51826`)
- [ ] Homebridge logs show "Advertiser started"
- [ ] Pairing code/QR visible in web UI
- [ ] iPhone and server on same subnet (no VLANs blocking traffic)
- [ ] No router/AP client isolation enabled
- [ ] Windows firewall rule allows TCP 51826

## References

- [HomeKit Accessory Protocol (HAP)](https://developer.apple.com/homekit/)
- [RFC 6762: Multicast DNS](https://datatracker.ietf.org/doc/html/rfc6762)
- [Homebridge Docker Documentation](https://github.com/homebridge/docker-homebridge)
