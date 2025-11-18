pipeline {
    agent any
    
    environment {
        // Docker Hub credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')

        // AWS credentials
        AWS_CREDENTIALS = credentials('aws-credentials')

        // GitHub token
        GITHUB_TOKEN = credentials('github-token')

        // EC2 SSH key
        EC2_SSH_KEY = credentials('ec2-ssh-key')

        // EC2 details
        EC2_USER = "ubuntu"
        EC2_PUBLIC_IP = "65.2.79.35"

        // Determine environment based on branch
        ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'prod' : 'dev'}"

        // Docker repositories
        DOCKERHUB_PROD_REPO = "abhishek8056/prod"
        DOCKERHUB_DEV_REPO = "abhishek8056/dev"

        // Docker repository based on environment
        DOCKER_REPO = "${env.BRANCH_NAME == 'main' ? DOCKERHUB_PROD_REPO : DOCKERHUB_DEV_REPO}"

        // Version tag
        VERSION = "${env.BUILD_NUMBER}"
        IMAGE_TAG = "v1.0.${env.BUILD_NUMBER}"

        // Full image name
        DOCKER_IMAGE = "${DOCKER_REPO}:${IMAGE_TAG}"
        DOCKER_LATEST = "${DOCKER_REPO}:latest"
    }
    
    options {
        // Keep last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // Timeout after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        
        // Disable concurrent builds
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Checkout"
                    echo "=========================================="
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Environment: ${ENVIRONMENT}"
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "=========================================="
                }
                
                // Checkout code from Git
                checkout scm
                
                script {
                    // Get Git commit info
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    
                    env.GIT_COMMIT_MSG = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()
                    
                    echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                    echo "Commit Message: ${env.GIT_COMMIT_MSG}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Build Docker Image"
                    echo "=========================================="
                    echo "Image: ${DOCKER_IMAGE}"
                    echo "Latest: ${DOCKER_LATEST}"
                    echo "=========================================="
                }

                // Check if build directory exists
                sh "ls -la build/"

                // Build Docker image
                sh """
                    docker build \
                        -t ${DOCKER_IMAGE} \
                        -t ${DOCKER_LATEST} \
                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        --build-arg VCS_REF=${env.GIT_COMMIT_SHORT} \
                        --build-arg VERSION=${IMAGE_TAG} \
                        .
                """

                // Verify image was created
                sh "docker images | grep ${DOCKER_REPO}"

                script {
                    // Get image size
                    env.IMAGE_SIZE = sh(
                        script: "docker images ${DOCKER_IMAGE} --format '{{.Size}}'",
                        returnStdout: true
                    ).trim()

                    echo "Image Size: ${env.IMAGE_SIZE}"
                }
            }
        }
        
        stage('Test Image') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Test Image"
                    echo "=========================================="
                }
                
                // Start container for testing
                sh """
                    docker run -d --name test-container-${BUILD_NUMBER} \
                        -p 8081:80 \
                        ${DOCKER_IMAGE}
                """
                
                // Wait for container to be ready
                sleep(time: 5, unit: 'SECONDS')
                
                // Test if container is running
                sh "docker ps | grep test-container-${BUILD_NUMBER}"
                
                // Test HTTP response
                script {
                    def response = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081",
                        returnStdout: true
                    ).trim()
                    
                    if (response != '200') {
                        error("Health check failed. HTTP status: ${response}")
                    }
                    
                    echo "Health check passed. HTTP status: ${response}"
                }
                
                // Clean up test container
                sh """
                    docker stop test-container-${BUILD_NUMBER}
                    docker rm test-container-${BUILD_NUMBER}
                """
                
                echo "Image test completed successfully"
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Push to Docker Hub"
                    echo "=========================================="
                    echo "Repository: ${DOCKER_REPO}"
                    echo "Environment: ${ENVIRONMENT}"
                    echo "=========================================="
                }
                
                // Login to Docker Hub
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                """
                
                // Push versioned image
                sh "docker push ${DOCKER_IMAGE}"
                echo "Pushed: ${DOCKER_IMAGE}"
                
                // Push latest tag
                sh "docker push ${DOCKER_LATEST}"
                echo "Pushed: ${DOCKER_LATEST}"
                
                echo "Images pushed successfully to Docker Hub"
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Deploy to EC2"
                    echo "=========================================="
                    echo "Environment: ${ENVIRONMENT}"
                    echo "Image: ${DOCKER_IMAGE}"
                    echo "=========================================="
                }
                
                // Deploy to EC2 using SSH
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_PUBLIC_IP} << 'ENDSSH'
                        
                        # Login to Docker Hub
                        echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                        
                        # Pull latest image
                        echo "Pulling image: ${DOCKER_IMAGE}"
                        docker pull ${DOCKER_IMAGE}
                        
                        # Stop and remove old container
                        CONTAINER_NAME="react-app-${ENVIRONMENT}"
                        if docker ps -a | grep -q \$CONTAINER_NAME; then
                            echo "Stopping existing container: \$CONTAINER_NAME"
                            docker stop \$CONTAINER_NAME || true
                            docker rm \$CONTAINER_NAME || true
                        fi
                        
                        # Start new container
                        echo "Starting new container: \$CONTAINER_NAME"
                        docker run -d \\
                            --name \$CONTAINER_NAME \\
                            -p 80:80 \\
                            --restart unless-stopped \\
                            ${DOCKER_IMAGE}
                        
                        # Wait for container to start
                        sleep 5
                        
                        # Verify container is running
                        if docker ps | grep -q \$CONTAINER_NAME; then
                            echo "Container is running successfully"
                        else
                            echo "Container failed to start"
                            docker logs \$CONTAINER_NAME
                            exit 1
                        fi
                        
                        # Clean up old images
                        echo "Cleaning up old images..."
                        docker image prune -f
                        
                        echo "Deployment completed successfully"
ENDSSH
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Health Check"
                    echo "=========================================="
                    echo "URL: http://${EC2_PUBLIC_IP}"
                    echo "=========================================="
                }
                
                // Wait for application to be ready
                sleep(time: 10, unit: 'SECONDS')
                
                // Perform health check
                retry(3) {
                    script {
                        def response = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://3.110.178.40",
                            returnStdout: true
                        ).trim()

                        if (response != '200') {
                            error("Health check failed. HTTP status: ${response}")
                        }

                        echo "Health check passed. HTTP status: ${response}"
                    }
                }

                // Get response time
                script {
                    env.RESPONSE_TIME = sh(
                        script: "curl -s -o /dev/null -w '%{time_total}' http://3.110.178.40",
                        returnStdout: true
                    ).trim()

                    echo "Response Time: ${env.RESPONSE_TIME}s"
                }
                
                echo "Application is healthy and accessible"
            }
        }
    }
    
    post {
        success {
            script {
                echo "=========================================="
                echo "BUILD SUCCESSFUL"
                echo "=========================================="
                echo "Environment: ${ENVIRONMENT}"
                echo "Branch: ${env.BRANCH_NAME}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Image: ${DOCKER_IMAGE}"
                echo "Image Size: ${env.IMAGE_SIZE}"
                echo "Application URL: http://${EC2_PUBLIC_IP}"
                echo "Response Time: ${env.RESPONSE_TIME}s"
                echo "=========================================="
            }
            
            // Send success notification (optional)
            // emailext (
            //     subject: "Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //     body: """
            //         Build successful!
            //         
            //         Environment: ${ENVIRONMENT}
            //         Branch: ${env.BRANCH_NAME}
            //         Commit: ${env.GIT_COMMIT_SHORT}
            //         Image: ${DOCKER_IMAGE}
            //         URL: http://${EC2_PUBLIC_IP}
            //     """,
            //     to: "${NOTIFICATION_EMAIL}"
            // )
        }
        
        failure {
            script {
                echo "=========================================="
                echo "BUILD FAILED"
                echo "=========================================="
                echo "Environment: ${ENVIRONMENT}"
                echo "Branch: ${env.BRANCH_NAME}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "=========================================="
            }
            
            // Send failure notification (optional)
            // emailext (
            //     subject: "Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //     body: """
            //         Build failed!
            //         
            //         Environment: ${ENVIRONMENT}
            //         Branch: ${env.BRANCH_NAME}
            //         Commit: ${env.GIT_COMMIT_SHORT}
            //         
            //         Check console output: ${env.BUILD_URL}console
            //     """,
            //     to: "${NOTIFICATION_EMAIL}"
            // )
        }
        
        always {
            // Clean up Docker images
            sh 'docker image prune -f || true'
            
            // Archive build logs
            script {
                def logFile = "build-${ENVIRONMENT}-${IMAGE_TAG}-${env.BUILD_NUMBER}.log"
                sh "echo 'Build completed at: \$(date)' > ${logFile}"
            }
        }
    }
}
