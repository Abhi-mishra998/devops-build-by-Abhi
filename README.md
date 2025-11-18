# React Application DevOps Deployment

Complete CI/CD pipeline for deploying React application to AWS EC2 with Docker, Jenkins, and monitoring.

## Project Requirements

This project implements:
- React application deployment on AWS EC2 (HTTP port 80)
- Docker containerization (Dockerfile + docker-compose.yml)
- Bash scripts (build.sh + deploy.sh)
- Git workflow (dev and master branches)
- Docker Hub (dev public repo, prod private repo)
- Jenkins CI/CD with auto-triggers
- AWS EC2 t2.micro with Security Groups
- Monitoring system with health checks

## Project Structure

```
devops-build/
├── scripts/
│   ├── build.sh          # Build Docker images
│   └── deploy.sh         # Deploy to EC2
├── jenkins/
│   ├── Jenkinsfile       # CI/CD pipeline
│   └── jenkins-setup.sh  # Jenkins installation
├── monitoring/
│   └── docker-compose.yml # Monitoring system
├── docs/                 # Documentation
├── Dockerfile            # Container configuration
├── docker-compose.yml    # Docker compose config
├── nginx.conf            # Nginx configuration
├── .gitignore           # Git ignore rules
└── .dockerignore        # Docker ignore rules
```

## Quick Start

### 1. Build Docker Image

```bash
# For dev environment
./scripts/build.sh dev v1.0.0

# For prod environment
./scripts/build.sh prod v1.0.0
```

### 2. Deploy to EC2

```bash
# For dev environment
./scripts/deploy.sh dev v1.0.0

# For prod environment
./scripts/deploy.sh prod v1.0.0
```

### 3. Git Workflow

```bash
# Work on dev branch
git checkout -b dev
git add .
git commit -m "Your changes"
git push origin dev

# Merge to master for production
git checkout master
git merge dev
git push origin master
```

## Setup Instructions

### Prerequisites

1. **Docker** - Install Docker Desktop
2. **AWS Account** - Create EC2 instance (t2.micro)
3. **Docker Hub** - Create dev (public) and prod (private) repos
4. **Jenkins** - Set up Jenkins server

### AWS EC2 Setup

1. Launch t2.micro instance
2. Use AMI: `ami-02b8269d5e85954ef`
3. Configure Security Group:
   - HTTP (80): Open to all (0.0.0.0/0)
   - SSH (22): Your IP only
4. Install Docker on EC2
5. Save EC2 details to `.env` file

### Environment Variables

Create `.env` file:

```bash
# Docker Hub
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-token
DOCKERHUB_DEV_REPO=username/dev
DOCKERHUB_PROD_REPO=username/prod

# AWS EC2
EC2_PUBLIC_IP=xx.xx.xx.xx
EC2_USER=ec2-user
EC2_KEY_PATH=/path/to/key.pem
```

### Jenkins Setup

1. Install Jenkins
2. Configure credentials:
   - Docker Hub credentials
   - AWS credentials
   - GitHub token
   - EC2 SSH key
3. Create pipeline jobs for dev and master branches
4. Set up GitHub webhooks

## CI/CD Pipeline

### Dev Branch to Dev Repo
- Push to `dev` branch
- Jenkins auto-triggers
- Builds Docker image
- Pushes to Docker Hub dev repo (public)
- Deploys to EC2

### Master Branch to Prod Repo
- Merge `dev` to `master`
- Jenkins auto-triggers
- Builds Docker image
- Pushes to Docker Hub prod repo (private)
- Deploys to EC2

## Monitoring

Health check monitoring system:
- Monitors application status
- Sends notifications on downtime
- Open-source solution

Start monitoring:
```bash
cd monitoring
docker-compose up -d
```

## Documentation

- `docs/SETUP.md` - Complete setup guide
- `docs/AWS-SETUP.md` - AWS EC2 configuration
- `docs/DOCKERHUB-SETUP.md` - Docker Hub setup
- `docs/GIT-WORKFLOW.md` - Git workflow guide
- `docs/SCREENSHOT-GUIDE.md` - Screenshots for submission
- `docs/TROUBLESHOOTING.md` - Common issues

## Submission Requirements

### URLs to Submit
1. GitHub repository URL
2. Deployed site URL (http://EC2_IP)
3. Docker Hub image names

### Screenshots Required
1. Jenkins login page
2. Jenkins configuration settings
3. Jenkins execute step commands
4. AWS EC2 Console
5. AWS Security Group configuration
6. Docker Hub repos with image tags
7. Deployed site page
8. Monitoring health check status

## Architecture

```
Developer -> GitHub (dev/master) -> Jenkins -> Docker Hub (dev/prod) -> AWS EC2
                                                                           |
                                                                      Monitoring
```

## Key Features

- **Automated CI/CD**: Push code and auto-deploy
- **Multi-Environment**: Separate dev and prod pipelines
- **Security**: Private prod repo, restricted SSH
- **Monitoring**: Real-time health checks with alerts
- **Simple Scripts**: Clean bash scripts without colors

## License

This project is for educational purposes.
