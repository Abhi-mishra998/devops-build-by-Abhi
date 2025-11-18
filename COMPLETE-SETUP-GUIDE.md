#### Dev Pipeline

1. New Item
2. Name: react-app-dev
3. Type: Pipeline
4. Configure:
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/sriram-R-krishnan/devops-build
     - Credentials: (none for public repo)
     - Branch: \*/dev
     - Script Path: Jenkinsfile
5. Save

#### Prod Pipeline

1. New Item
2. Name: react-app-prod
3. Type: Pipeline
4. Configure:
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/sriram-R-krishnan/devops-build
     - Credentials: (none for public repo)
     - Branch: \*/master
     - Script Path: Jenkinsfile
5. Save

---

## Step 5: GitHub Configuration

### 5.1 Create GitHub Repository

1. Go to https://github.com/
2. New repository
3. Name: devops-build
4. Public
5. Create repository

### 5.3 Create Dev Branch

```bash
git checkout -b dev
git push -u origin dev
```

### 5.4 Configure GitHub Webhook

1. Go to repository Settings
2. Webhooks > Add webhook
3. Payload URL: http://YOUR_JENKINS_IP:8080/github-webhook/
4. Content type: application/json
5. Events: Just the push event
6. Active: Check
7. Add webhook

---

## Step 6: Build and Deploy

### 6.1 Manual Build (First Time)

#### Build Docker Image

```bash
./scripts/build.sh dev v1.0.0
```

This will:

- Build Docker image
- Test locally
- Push to Docker Hub dev repo

#### Deploy to EC2

```bash
./scripts/deploy.sh dev v1.0.0
```

This will:

- SSH to EC2
- Pull Docker image
- Stop old container
- Start new container

### 6.2 Verify Deployment

```bash
# Check application
curl http://YOUR_EC2_IP

# Or open in browser
http://YOUR_EC2_IP
```

### 6.3 Automated Build (Jenkins)

#### Test Dev Pipeline

```bash
# Make a change
echo "test" > test.txt

# Commit and push to dev
git checkout dev
git add test.txt
git commit -m "Test dev pipeline"
git push origin dev

# Jenkins will auto-trigger
# Check Jenkins dashboard for build status
```

#### Test Prod Pipeline

```bash
# Merge dev to main
git checkout main
git merge dev
git push origin main

# Jenkins will auto-trigger
# Check Jenkins dashboard for build status
```

---

## Step 7: Monitoring Setup

### 7.1 Start Monitoring System

```bash
./monitoring/start-monitoring.sh
```

### 7.2 Access Dashboard

Open browser: http://localhost:3001

### 7.3 Initial Setup

1. Create admin account
   - Username: admin
   - Password: (your secure password)

### 7.4 Add Monitor

1. Click "Add New Monitor"
2. Configuration:
   - Monitor Type: HTTP(s)
   - Friendly Name: React App Production
   - URL: http://YOUR_EC2_IP
   - Heartbeat Interval: 60 seconds
   - Retries: 3
3. Save

### 7.5 Configure Email Notifications

#### Get Gmail App Password

1. Go to Google Account
2. Security > 2-Step Verification (enable)
3. Security > App passwords
4. Generate password for "Mail"
5. Copy 16-character password

#### Setup in Uptime Kuma

1. Settings > Notifications
2. Setup Notification
3. Type: Email (SMTP)
4. Configuration:
   - Friendly Name: Email Alert
   - SMTP Host: smtp.gmail.com
   - SMTP Port: 587
   - Security: TLS
   - Username: your-email@gmail.com
   - Password: (app password)
   - From: your-email@gmail.com
   - To: recipient@example.com
5. Test
6. Save

### 7.6 Link Notification to Monitor

1. Edit your monitor
2. Notifications section
3. Toggle ON your email notification
4. Save

---

## Step 8: Testing

### 8.1 Test Docker Build Locally

```bash
# Build image
docker build -t test-app .

# Run container
docker run -d -p 8080:80 test-app

# Test
curl http://localhost:8080

# Cleanup
docker stop $(docker ps -q --filter ancestor=test-app)
docker rm $(docker ps -aq --filter ancestor=test-app)
```

### 8.2 Test Scripts

```bash
# Test build script
./scripts/build.sh dev v1.0.1

# Test deploy script
./scripts/deploy.sh dev v1.0.1
```

### 8.3 Test Jenkins Pipeline

```bash
# Trigger dev build
git checkout dev
git commit --allow-empty -m "Test build"
git push origin dev

# Check Jenkins dashboard
# Verify build succeeds
```

### 8.4 Test Monitoring

```bash
# Stop application on EC2
ssh -i ~/.ssh/devops-key.pem ec2-user@YOUR_EC2_IP
docker stop react-app-dev
exit

# Wait 3-5 minutes
# Check email for downtime alert

# Start application
ssh -i ~/.ssh/devops-key.pem ec2-user@YOUR_EC2_IP
docker start react-app-dev
exit

# Check email for recovery notification
```

---

## Step 9: Submission

### 9.1 Collect URLs

1. GitHub Repository: https://github.com/sriram-R-krishnan/devops-build
2. Deployed Application: http://YOUR_EC2_IP
3. Docker Hub Dev Repo: https://hub.docker.com/r/your-username/dev
4. Docker Hub Prod Repo: https://hub.docker.com/r/your-username/prod

### 9.2 Capture Screenshots

#### Jenkins Screenshots

1. Jenkins login page
2. Jenkins dashboard with pipelines
3. Pipeline configuration page
4. Build console output (successful build)
5. Build history

#### AWS Screenshots

1. EC2 Console showing running instance
2. EC2 instance details
3. Security Group inbound rules
4. Security Group outbound rules

#### Docker Hub Screenshots

1. Dev repository with image tags
2. Prod repository with image tags
3. Repository settings showing visibility

#### Application Screenshots

1. Deployed application homepage
2. Browser showing application URL

#### Monitoring Screenshots

1. Uptime Kuma dashboard
2. Monitor configuration
3. Notification settings
4. Alert history

### 9.3 Create Submission Document

Create a document with:

- All URLs
- All screenshots
- Brief description of setup
- Any challenges faced

---

## Step 10: Troubleshooting

### Docker Issues

```bash
# Docker not running
sudo systemctl start docker

# Permission denied
sudo usermod -aG docker $USER
# Logout and login again

# Image build fails
docker system prune -a
```

### EC2 Issues

```bash
# Cannot SSH
chmod 400 ~/.ssh/devops-key.pem
# Check Security Group allows SSH from your IP

# Application not accessible
# Check Security Group allows HTTP from 0.0.0.0/0
# Check Docker container is running on EC2
```

### Jenkins Issues

```bash
# Build fails
# Check credentials are configured
# Check environment variables are set
# Check EC2 is accessible from Jenkins

# Webhook not triggering
# Check webhook URL is correct
# Check Jenkins is accessible from internet
```

### Monitoring Issues

```bash
# Cannot access dashboard
docker-compose -f monitoring/docker-compose.yml restart

# Email not sending
# Use Gmail App Password, not regular password
# Check SMTP settings
```

---

## Quick Reference Commands

### Build and Deploy

```bash
# Build dev
./scripts/build.sh dev v1.0.0

# Deploy dev
./scripts/deploy.sh dev v1.0.0

# Build prod
./scripts/build.sh prod v1.0.0

# Deploy prod
./scripts/deploy.sh prod v1.0.0
```

### Git Workflow

```bash
# Work on dev
git checkout dev
git add .
git commit -m "Your message"
git push origin dev

# Deploy to prod
git checkout master
git merge dev
git push origin master
```

### Docker Commands

```bash
# View images
docker images

# View containers
docker ps -a

# View logs
docker logs container-name

# Clean up
docker system prune -a
```

### EC2 Commands

```bash
# SSH to EC2
ssh -i ~/.ssh/devops-key.pem ec2-user@YOUR_EC2_IP

# Check Docker on EC2
docker ps

# View logs on EC2
docker logs react-app-dev
```

### Monitoring Commands

```bash
# Start monitoring
./monitoring/start-monitoring.sh

# View logs
docker-compose -f monitoring/docker-compose.yml logs -f

# Stop monitoring
docker-compose -f monitoring/docker-compose.yml stop

# Restart monitoring
docker-compose -f monitoring/docker-compose.yml restart
```

---

## Completion Checklist

- [ ] Docker Desktop installed
- [ ] Git installed
- [ ] AWS account created
- [ ] Docker Hub account created
- [ ] GitHub account created
- [ ] Repository cloned
- [ ] .env file configured
- [ ] Docker Hub repositories created
- [ ] EC2 instance launched
- [ ] Security Group configured
- [ ] SSH connection tested
- [ ] Jenkins installed
- [ ] Jenkins credentials configured
- [ ] Jenkins pipelines created
- [ ] GitHub webhooks configured
- [ ] Manual build successful
- [ ] Manual deploy successful
- [ ] Application accessible
- [ ] Automated build tested
- [ ] Monitoring system running
- [ ] Email notifications working
- [ ] All screenshots captured
- [ ] Submission document ready

---

## Support

If you encounter issues:

1. Check docs/TROUBLESHOOTING.md
2. Review error messages carefully
3. Verify all credentials are correct
4. Ensure all services are running
5. Check firewall/security group settings

---

**Your DevOps pipeline is now complete and ready for submission!**

- Branch: _/dev and _/master
