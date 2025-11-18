# Monitoring System

Simple health check monitoring for the React application using Uptime Kuma (open-source).

## Features

- Health status monitoring
- Downtime notifications via email/Slack/Discord
- Web dashboard
- Open-source solution

## Quick Start

### 1. Start Monitoring

```bash
./monitoring/start-monitoring.sh
```

### 2. Access Dashboard

Open in browser: http://localhost:3001

### 3. Initial Setup

1. Create admin account (first time only)
2. Click "Add New Monitor"
3. Configure monitor:
   - Monitor Type: HTTP(s)
   - Friendly Name: React App Production
   - URL: http://YOUR_EC2_PUBLIC_IP
   - Heartbeat Interval: 60 seconds
   - Retries: 3

### 4. Configure Notifications

#### Email Notification

1. Go to Settings > Notifications
2. Click "Setup Notification"
3. Select "Email (SMTP)"
4. Configure:
   - Friendly Name: Email Alert
   - SMTP Host: smtp.gmail.com
   - SMTP Port: 587
   - Security: TLS
   - Username: your-email@gmail.com
   - Password: your-app-password
   - From Email: your-email@gmail.com
   - To Email: recipient@example.com
5. Test and Save

#### Slack Notification (Optional)

1. Create Slack webhook: https://api.slack.com/messaging/webhooks
2. In Uptime Kuma: Settings > Notifications
3. Select "Slack"
4. Enter webhook URL
5. Test and Save

#### Discord Notification (Optional)

1. Create Discord webhook in your server
2. In Uptime Kuma: Settings > Notifications
3. Select "Discord"
4. Enter webhook URL
5. Test and Save

### 5. Link Notification to Monitor

1. Edit your monitor
2. Scroll to "Notifications"
3. Select your configured notification
4. Save

## Configuration

Edit `alert-config.example.json` for reference configuration.

## Usage

### View Logs
```bash
docker-compose -f monitoring/docker-compose.yml logs -f
```

### Stop Monitoring
```bash
docker-compose -f monitoring/docker-compose.yml stop
```

### Restart Monitoring
```bash
docker-compose -f monitoring/docker-compose.yml restart
```

### Remove Monitoring
```bash
docker-compose -f monitoring/docker-compose.yml down
```

## How It Works

1. Uptime Kuma checks your application URL every 60 seconds
2. If application is down (3 failed retries), sends notification
3. When application recovers, sends recovery notification
4. All status visible in web dashboard

## Requirements

- Docker and Docker Compose installed
- Port 3001 available
- Email account for notifications (Gmail recommended)

## Troubleshooting

### Port 3001 Already in Use
```bash
# Stop existing service
docker-compose -f monitoring/docker-compose.yml down

# Or use different port in docker-compose.yml
ports:
  - "3002:3001"
```

### Cannot Send Email
- Use Gmail App Password (not regular password)
- Enable "Less secure app access" in Gmail settings
- Check SMTP settings are correct

### Monitor Shows Down But App is Up
- Check EC2 Security Group allows HTTP from monitoring server
- Verify URL is correct
- Check application is actually running

## Screenshots for Submission

Capture these screenshots:
1. Uptime Kuma dashboard showing monitor status
2. Monitor configuration page
3. Notification settings
4. Alert history showing downtime detection

## Notes

- Uptime Kuma stores data in Docker volume
- Data persists across container restarts
- Access dashboard from any browser on network
- Supports multiple monitors and notification channels
