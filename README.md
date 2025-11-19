# React Application – DevOps CI/CD Deployment Pipeline

> A production-grade DevOps pipeline demonstrating automated deployment of a React application to AWS EC2 using Docker, Jenkins, and industry-standard practices.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com)
[![Docker](https://img.shields.io/badge/docker-enabled-blue)](https://docker.com)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange)](https://aws.amazon.com)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-red)](https://jenkins.io)

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [CI/CD Workflow](#cicd-workflow)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Submission Checklist](#submission-checklist)
- [Future Enhancements](#future-enhancements)

---

## Overview

This repository showcases a complete DevOps implementation for deploying a React application with automated CI/CD pipelines. The project demonstrates real-world practices used by modern software companies to ship production-ready applications efficiently and reliably.

### What This Project Delivers

- **Automated CI/CD** – Zero-touch deployment from code commit to production
- **Environment Separation** – Distinct dev and prod environments with isolated workflows
- **Containerization** – Docker-based deployment ensuring consistency across environments
- **Cloud Deployment** – AWS EC2 hosting with security best practices
- **Monitoring** – Health checks and uptime tracking for reliability
- **Version Control** – Semantic versioning with automated tagging

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Jenkins Automation** | GitHub webhook-triggered builds with automated testing and deployment |
| **Docker Hub Integration** | Public dev repository and private prod repository for image management |
| **Multi-Environment** | Separate dev and prod pipelines with environment-specific configurations |
| **Automated Scripts** | Bash scripts for building, testing, and deploying applications |
| **AWS EC2 Deployment** | SSH-based automated deployment to cloud infrastructure |
| **Health Monitoring** | Container health checks with uptime tracking and alerting |
| **Security** | Private prod images, SSH key authentication, and restricted access |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVELOPER                                │
│                    (Git Commit & Push)                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB REPOSITORY                           │
│                    (Webhook Trigger)                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      JENKINS CI/CD                               │
│         ┌────────────────────────────────────┐                  │
│         │  Build → Test → Dockerize → Push   │                  │
│         └────────────────────────────────────┘                  │
└──────────────┬────────────────────────┬───────────────────────┘
               │                        │
               ▼                        ▼
    ┌──────────────────┐    ┌──────────────────┐
    │   DOCKER HUB     │    │   DOCKER HUB     │
    │   (Dev - Public) │    │  (Prod - Private)│
    └────────┬─────────┘    └────────┬─────────┘
             │                       │
             ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │   AWS EC2 DEV    │    │   AWS EC2 PROD   │
    │   Port: 80       │    │   Port: 80       │
    │   React App      │    │   React App      │
    └────────┬─────────┘    └────────┬─────────┘
             │                       │
             └───────────┬───────────┘
                         ▼
              ┌──────────────────────┐
              │  MONITORING SYSTEM   │
              │  Health & Uptime     │
              └──────────────────────┘
```

---

## Technology Stack

### Core Technologies
- **Frontend**: React 18
- **Web Server**: Nginx
- **Containerization**: Docker & Docker Compose
- **CI/CD**: Jenkins
- **Cloud Provider**: AWS EC2
- **Version Control**: Git & GitHub

### DevOps Tools
- **Container Registry**: Docker Hub
- **Automation**: Bash Scripting
- **Monitoring**: Custom Docker-based solution
- **Security**: SSH Key Authentication

---

## Project Structure

```
devops-build-by-Abhi/
│
├── scripts/
│   ├── build.sh              # Automated Docker build pipeline
│   └── deploy.sh             # AWS EC2 deployment automation
│
├── monitoring/
│   └── docker-compose.yml    # Monitoring stack configuration
│
├── build/                    # Pre-built React application
│
├── Dockerfile                # Multi-stage container build
├── docker-compose.yml        # Local development stack
├── nginx.conf                # Nginx configuration
├── Jenkinsfile               # Pipeline as code
├── .env.example              # Environment variables template
├── .dockerignore
├── .gitignore
└── README.md
```

---

## Getting Started

### Prerequisites

- Docker 20.10+
- Jenkins 2.300+
- AWS Account with EC2 access
- Docker Hub account
- Git

### Local Setup

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/devops-build-by-Abhi.git
cd devops-build-by-Abhi
```

**2. Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your credentials
```

**3. Build and run locally**
```bash
docker-compose up -d
```

**4. Access the application**
```
http://localhost:8080
```

---

## CI/CD Workflow

### Development Pipeline (dev branch)

```
Code Push → GitHub Webhook → Jenkins Trigger → Build Image → Run Tests → 
Tag (dev:vX.Y.Z) → Push to Docker Hub → Deploy to EC2 Dev → Health Check
```

**Triggered by:** Push to `dev` branch  
**Image Tags:** `dev:latest`, `dev:vX.Y.Z`  
**Repository:** Public Docker Hub  
**Deployment:** Development EC2 instance

### Production Pipeline (main branch)

```
PR Merge → GitHub Webhook → Jenkins Trigger → Build Image → Security Scan → 
Tag (prod:vX.Y.Z) → Push to Private Hub → Deploy to EC2 Prod → Validation
```

**Triggered by:** Merge to `main` branch  
**Image Tags:** `prod:latest`, `prod:vX.Y.Z`  
**Repository:** Private Docker Hub  
**Deployment:** Production EC2 instance

---

## Deployment

### Build Script

Build Docker images with automated tagging and testing:

```bash
# Development build
./scripts/build.sh dev v1.0.0

# Production build
./scripts/build.sh prod v1.0.0
```

**Features:**
- Automatic port detection
- Multi-tag image creation
- Temporary container testing
- Automated cleanup
- Build metadata logging

**Environment Variables:**
```bash
HOST_PORT=8085          # Custom port (optional)
SKIP_PUSH=1             # Skip Docker Hub push
DOCKERHUB_USERNAME=     # Your Docker Hub username
DOCKERHUB_TOKEN=        # Your Docker Hub token
```

### Deploy Script

Deploy to AWS EC2 with automated rollout:

```bash
# Deploy to development
./scripts/deploy.sh dev v1.0.0

# Deploy to production
./scripts/deploy.sh prod v1.0.0
```

**Features:**
- SSH-based deployment
- Zero-downtime updates
- Automated health checks
- Container cleanup
- Deployment logging

**Required Variables (.env):**
```bash
EC2_PUBLIC_IP=xx.xx.xx.xx
EC2_USER=ubuntu
EC2_KEY_PATH=/path/to/key.pem
DOCKERHUB_USERNAME=yourname
DOCKERHUB_TOKEN=yourtoken
```

---

## Monitoring

### Setup Monitoring Stack

```bash
cd monitoring
docker-compose up -d
```

### Monitoring Features

- **Uptime Tracking** – Continuous application availability monitoring
- **Health Checks** – Automated endpoint verification
- **Container Status** – Real-time container health monitoring
- **Alert System** – Configurable downtime notifications

### Access Monitoring Dashboard

```
http://your-ec2-ip:3000
```

---

## AWS EC2 Configuration

### Recommended Specifications

| Component | Specification |
|-----------|--------------|
| **Instance Type** | t2.micro (Free Tier) |
| **Operating System** | Ubuntu 22.04 LTS |
| **Storage** | 8GB EBS Volume |
| **vCPUs** | 1 |
| **Memory** | 1GB |

### Security Group Rules

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| HTTP | 80 | 0.0.0.0/0 | Application access |
| SSH | 22 | Your IP | Administrative access |
| Custom | 3000 | Your IP | Monitoring dashboard |

### EC2 Initial Setup

```bash
# Update system
sudo apt update -y && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io -y

# Add user to Docker group
sudo usermod -aG docker ubuntu

# Restart session
newgrp docker

# Verify installation
docker --version
```

---

## Troubleshooting

### Docker Issues

**Problem:** Permission denied when accessing Docker socket

```bash
sudo usermod -aG docker $USER
sudo systemctl restart docker
newgrp docker
```

**Problem:** Port already in use

```bash
# Find process using port
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>
```

**Problem:** Container keeps restarting

```bash
# Check container logs
docker logs <container-name>

# Inspect container
docker inspect <container-name>
```

### Jenkins Issues

**Problem:** Jenkins cannot access Docker

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**Problem:** Webhook not triggering builds

- Verify GitHub webhook URL
- Check Jenkins GitHub plugin configuration
- Review Jenkins system logs: `/var/log/jenkins/jenkins.log`

**Problem:** SSH deployment fails

```bash
# Verify SSH key permissions
chmod 400 /path/to/key.pem

# Test SSH connection
ssh -i /path/to/key.pem ubuntu@ec2-ip

# Check security group allows SSH from Jenkins IP
```

### Application Issues

**Problem:** Application not accessible on browser

```bash
# Check if container is running
docker ps

# View application logs
docker logs react-app-dev

# Test locally on EC2
curl http://localhost

# Check Nginx configuration
docker exec react-app-dev cat /etc/nginx/conf.d/default.conf
```

**Problem:** Health check fails

```bash
# Manual health check
curl -f http://localhost/health || echo "Health check failed"

# Restart container
docker restart react-app-dev
```

### GitHub Issues

**Problem:** Push blocked due to exposed secrets

```bash
# Remove secret from commit
git reset --soft HEAD~1

# Update .env.example (remove actual secrets)
git add .env.example
git commit -m "fix: remove exposed secrets"

# Force push (use with caution)
git push --force
```

---

## Submission Checklist

### Required Deliverables

- [ ] GitHub Repository URL
- [ ] Docker Hub Dev Repository URL
- [ ] Docker Hub Prod Repository URL
- [ ] Live Application URL (EC2 Public IP)
- [ ] Jenkins Pipeline Screenshot
- [ ] Build Logs Screenshot
- [ ] Deployment Logs Screenshot
- [ ] Monitoring Dashboard Screenshot
- [ ] AWS Security Group Configuration Screenshot
- [ ] Docker Hub Repository Screenshots

### Documentation

- [ ] README.md (this file)
- [ ] Architecture diagram
- [ ] CI/CD workflow documentation
- [ ] Troubleshooting guide
- [ ] Environment setup instructions

---

## Future Enhancements

### Infrastructure
- **HTTPS Integration** – Let's Encrypt SSL certificates for secure connections
- **Load Balancing** – Nginx reverse proxy with multiple backend instances
- **Auto Scaling** – AWS Auto Scaling Groups for dynamic capacity
- **Infrastructure as Code** – Terraform for reproducible infrastructure

### DevOps Improvements
- **Blue-Green Deployment** – Zero-downtime deployment strategy
- **Canary Releases** – Gradual rollout with traffic splitting
- **Rollback Automation** – Automated rollback on deployment failures
- **Multi-Region Deployment** – Global application distribution

### Monitoring & Observability
- **Prometheus + Grafana** – Advanced metrics and visualization
- **ELK Stack** – Centralized logging and analysis
- **Alert Manager** – Slack/Email/PagerDuty integration
- **AIOps Integration** – ML-based anomaly detection

### Security Enhancements
- **Secrets Management** – HashiCorp Vault or AWS Secrets Manager
- **Image Scanning** – Trivy/Clair for vulnerability detection
- **SAST/DAST** – Static and dynamic security testing
- **Compliance Monitoring** – Automated security compliance checks

---

## License

This project is created for educational and demonstration purposes.

---

## Contact & Support

For questions or suggestions, please open an issue on GitHub.

---

<div align="center">

*Author- Abhishek-Mishra*



</div>
