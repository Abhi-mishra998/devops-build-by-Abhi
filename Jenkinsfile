pipeline {
    agent any

    environment {
        // Notification email
        NOTIFY_EMAIL = "opensourcetesting8056@gmail.com"

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
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Checkout"
                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Environment: ${ENVIRONMENT}"
                    echo "=========================================="
                }

                checkout scm

                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.GIT_COMMIT_MSG = sh(
                        script: "git log -1 --pretty=%B",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "ls -la build/"

                sh """
                    docker build \
                        -t ${DOCKER_IMAGE} \
                        -t ${DOCKER_LATEST} \
                        --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        --build-arg VCS_REF=${env.GIT_COMMIT_SHORT} \
                        --build-arg VERSION=${IMAGE_TAG} \
                        .
                """

                sh "docker images | grep ${DOCKER_REPO}"

                script {
                    env.IMAGE_SIZE = sh(
                        script: "docker images ${DOCKER_IMAGE} --format '{{.Size}}'",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Test Image') {
            steps {
                sh """
                    docker run -d --name test-container-${BUILD_NUMBER} \
                        -p 8081:80 \
                        ${DOCKER_IMAGE}
                """

                sleep(5)

                sh "docker ps | grep test-container-${BUILD_NUMBER}"

                script {
                    def response = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081",
                        returnStdout: true
                    ).trim()

                    if (response != '200') {
                        error("Health check failed: ${response}")
                    }
                }

                sh """
                    docker stop test-container-${BUILD_NUMBER}
                    docker rm test-container-${BUILD_NUMBER}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh """
                    echo \$DOCKERHUB_CREDENTIALS_PSW | docker login -u \$DOCKERHUB_CREDENTIALS_USR --password-stdin
                """

                sh "docker push ${DOCKER_IMAGE}"
                sh "docker push ${DOCKER_LATEST}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_PUBLIC_IP} << 'ENDSSH'

                        echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                        docker pull ${DOCKER_IMAGE}

                        CONTAINER_NAME="react-app-${ENVIRONMENT}"

                        if docker ps -a | grep -q \$CONTAINER_NAME; then
                            docker stop \$CONTAINER_NAME || true
                            docker rm \$CONTAINER_NAME || true
                        fi

                        docker run -d \
                            --name \$CONTAINER_NAME \
                            -p 80:80 \
                            --restart unless-stopped \
                            ${DOCKER_IMAGE}

                        sleep 5

                        docker image prune -f
ENDSSH
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sleep(10)

                retry(3) {
                    script {
                        def response = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://${EC2_PUBLIC_IP}",
                            returnStdout: true
                        ).trim()

                        if (response != '200') {
                            error("Health check failed: ${response}")
                        }
                    }
                }

                script {
                    env.RESPONSE_TIME = sh(
                        script: "curl -s -o /dev/null -w '%{time_total}' http://${EC2_PUBLIC_IP}",
                        returnStdout: true
                    ).trim()
                }
            }
        }
    }

    post {

        success {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Build Status: SUCCESS

Environment: ${ENVIRONMENT}
Branch: ${env.BRANCH_NAME}
Commit: ${env.GIT_COMMIT_SHORT}
Image: ${DOCKER_IMAGE}
URL: http://${EC2_PUBLIC_IP}

Build URL: ${env.BUILD_URL}

-- Jenkins Notification System
""",
                mimeType: 'text/plain'
            )
        }

        failure {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Build Status: FAILED 

Environment: ${ENVIRONMENT}
Branch: ${env.BRANCH_NAME}
Commit: ${env.GIT_COMMIT_SHORT}

Check console output:
${env.BUILD_URL}console

-- Jenkins Notification System
""",
                mimeType: 'text/plain'
            )
        }

        unstable {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Build Status: UNSTABLE 

Job: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}

Check console output:
${env.BUILD_URL}

-- Jenkins Notification System
""",
                mimeType: 'text/plain'
            )
        }

        aborted {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "ABORTED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Build Status: ABORTED 

The build was manually stopped.

Build: #${env.BUILD_NUMBER}
Job: ${env.JOB_NAME}

-- Jenkins Notification System
""",
                mimeType: 'text/plain'
            )
        }

        always {
            sh 'docker image prune -f || true'
        }
    }
}
