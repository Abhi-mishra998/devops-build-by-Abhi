# Jenkins Requirements Checklist

## Jenkinsfile Verification

### Requirements Met

#### 1. Auto-Build Trigger from Dev Branch
- [x] Pipeline triggers on push to dev branch
- [x] Builds Docker image
- [x] Pushes to Docker Hub dev repo (public)
- [x] Deploys to EC2

#### 2. Auto-Build Trigger from Master Branch
- [x] Pipeline triggers on push to master branch
- [x] Builds Docker image
- [x] Pushes to Docker Hub prod repo (private)
- [x] Deploys to EC2

#### 3. Environment-Based Configuration
- [x] ENVIRONMENT variable: 'dev' or 'prod' based on branch
- [x] DOCKER_REPO variable: switches between dev/prod repos
- [x] Container naming: react-app-dev or react-app-prod

#### 4. Pipeline Stages
- [x] Checkout: Get code from GitHub
- [x] Build: Build Docker image
- [x] Test: Test image locally
- [x] Push: Push to Docker Hub
- [x] Deploy: Deploy to EC2
- [x] Health Check: Verify deployment

#### 5. Credentials Required
- [x] dockerhub-credentials: Docker Hub username and token
- [x] ec2-ssh-key: SSH key for EC2 access
- [x] aws-credentials: AWS access keys (optional)
- [x] github-token: GitHub personal access token (optional)

#### 6. Environment Variables Required
- [x] DOCKERHUB_DEV_REPO: Dev repository name
- [x] DOCKERHUB_PROD_REPO: Prod repository name
- [x] EC2_PUBLIC_IP: EC2 instance IP address
- [x] EC2_USER: EC2 username (ec2-user)

## Jenkins Configuration Steps

### 1. Install Jenkins

```bash
# Run Jenkins setup script
./jenkins/jenkins-setup.sh
```

### 2. Configure Credentials

#### Docker Hub Credentials
1. Jenkins Dashboard > Manage Jenkins > Credentials
2. Click "Global" > "Add Credentials"
3. Kind: Username with password
4. ID: dockerhub-credentials
5. Username: your-dockerhub-username
6. Password: your-dockerhub-token
7. Save

#### EC2 SSH Key
1. Jenkins Dashboard > Manage Jenkins > Credentials
2. Click "Global" > "Add Credentials"
3. Kind: SSH Username with private key
4. ID: ec2-ssh-key
5. Username: ec2-user
6. Private Key: Enter directly (paste your .pem file content)
7. Save

#### GitHub Token (Optional)
1. Jenkins Dashboard > Manage Jenkins > Credentials
2. Click "Global" > "Add Credentials"
3. Kind: Secret text
4. ID: github-token
5. Secret: your-github-personal-access-token
6. Save

### 3. Configure Environment Variables

1. Jenkins Dashboard > Manage Jenkins > System
2. Scroll to "Global properties"
3. Check "Environment variables"
4. Add variables:
   - Name: DOCKERHUB_DEV_REPO, Value: username/dev
   - Name: DOCKERHUB_PROD_REPO, Value: username/prod
   - Name: EC2_PUBLIC_IP, Value: xx.xx.xx.xx
   - Name: EC2_USER, Value: ec2-user
5. Save

### 4. Create Pipeline Jobs

#### Dev Pipeline
1. New Item > Pipeline
2. Name: react-app-dev
3. Configure:
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/sriram-R-krishnan/devops-build
     - Branch: */dev
     - Script Path: Jenkinsfile
4. Save

#### Prod Pipeline
1. New Item > Pipeline
2. Name: react-app-prod
3. Configure:
   - Build Triggers: GitHub hook trigger for GITScm polling
   - Pipeline:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/sriram-R-krishnan/devops-build
     - Branch: */master
     - Script Path: Jenkinsfile
4. Save

### 5. Configure GitHub Webhooks

#### For Dev Branch
1. Go to GitHub repository
2. Settings > Webhooks > Add webhook
3. Payload URL: http://YOUR_JENKINS_URL/github-webhook/
4. Content type: application/json
5. Events: Just the push event
6. Active: Check
7. Add webhook

#### For Master Branch
Same as dev (webhook triggers both pipelines based on branch)

## Pipeline Flow

### Dev Branch Flow
```
Push to dev branch
  |
  v
GitHub webhook triggers Jenkins
  |
  v
Jenkins pulls code from dev branch
  |
  v
Build Docker image
  |
  v
Test image locally
  |
  v
Push to Docker Hub dev repo (public)
  |
  v
Deploy to EC2
  |
  v
Health check
  |
  v
Success notification
```

### Master Branch Flow
```
Merge dev to master
  |
  v
Push to master branch
  |
  v
GitHub webhook triggers Jenkins
  |
  v
Jenkins pulls code from master branch
  |
  v
Build Docker image
  |
  v
Test image locally
  |
  v
Push to Docker Hub prod repo (private)
  |
  v
Deploy to EC2
  |
  v
Health check
  |
  v
Success notification
```

## Testing

### Test Dev Pipeline
```bash
# Make a change
echo "test" > test.txt

# Commit and push to dev
git checkout dev
git add test.txt
git commit -m "Test dev pipeline"
git push origin dev

# Check Jenkins dashboard
# Pipeline should auto-trigger
```

### Test Prod Pipeline
```bash
# Merge dev to master
git checkout master
git merge dev
git push origin master

# Check Jenkins dashboard
# Pipeline should auto-trigger
```

## Verification Checklist

### Before First Build
- [ ] Jenkins installed and running
- [ ] All credentials configured
- [ ] Environment variables set
- [ ] Pipeline jobs created
- [ ] GitHub webhooks configured
- [ ] EC2 instance running
- [ ] Docker Hub repos created

### After First Build
- [ ] Build triggered automatically
- [ ] Docker image built successfully
- [ ] Image pushed to correct repo (dev/prod)
- [ ] Application deployed to EC2
- [ ] Health check passed
- [ ] Application accessible via browser

## Screenshots for Submission

Capture these:
1. Jenkins login page
2. Jenkins dashboard with pipelines
3. Pipeline configuration page
4. Build console output
5. Successful build status
6. Credentials configuration (hide sensitive data)
7. Environment variables configuration

## Troubleshooting

### Build Not Triggering
- Check GitHub webhook is configured
- Check webhook delivery in GitHub settings
- Verify Jenkins URL is accessible from internet
- Check Jenkins GitHub plugin is installed

### Docker Push Failed
- Verify Docker Hub credentials are correct
- Check repository names match environment variables
- Ensure prod repo is private, dev repo is public

### Deployment Failed
- Check EC2 SSH key is correct
- Verify EC2 Security Group allows SSH from Jenkins
- Check EC2_PUBLIC_IP is correct
- Ensure Docker is installed on EC2

### Health Check Failed
- Verify application is running on EC2
- Check EC2 Security Group allows HTTP
- Ensure port 80 is not blocked
- Check application logs on EC2

## Requirements Summary

Your Jenkinsfile meets all requirements:
- Auto-triggers on dev and master branches
- Builds and pushes to correct Docker Hub repos
- Deploys to EC2 automatically
- Includes health checks
- Clean, professional code
- No emojis or special symbols
- Proper error handling
