#!/bin/bash

# Jenkins Installation Script
# Supports Ubuntu/Debian and CentOS/RHEL/Amazon Linux
# Usage: sudo ./jenkins/jenkins-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root or with sudo"
    exit 1
fi

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    print_info "Detected OS: $OS $OS_VERSION"
}

# Install Java
install_java() {
    print_header "Installing Java"
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y openjdk-11-jdk
            ;;
        centos|rhel|amzn)
            yum install -y java-11-openjdk java-11-openjdk-devel
            ;;
        *)
            print_error "Unsupported OS for automatic installation"
            exit 1
            ;;
    esac
    
    # Verify Java installation
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        print_success "Java installed: $JAVA_VERSION"
    else
        print_error "Java installation failed"
        exit 1
    fi
}

# Install Jenkins
install_jenkins() {
    print_header "Installing Jenkins"
    
    case $OS in
        ubuntu|debian)
            print_info "Installing Jenkins on Ubuntu/Debian..."
            
            # Add Jenkins repository key
            wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
            
            # Add Jenkins repository
            sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
            
            # Update and install
            apt-get update
            apt-get install -y jenkins
            ;;
        
        centos|rhel|amzn)
            print_info "Installing Jenkins on CentOS/RHEL/Amazon Linux..."
            
            # Add Jenkins repository
            wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
            rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
            
            # Install Jenkins
            yum install -y jenkins
            ;;
        
        *)
            print_error "Unsupported OS for automatic installation"
            exit 1
            ;;
    esac
    
    print_success "Jenkins installed successfully"
}

# Start Jenkins service
start_jenkins() {
    print_header "Starting Jenkins Service"
    
    # Start Jenkins
    systemctl start jenkins
    
    # Enable Jenkins to start on boot
    systemctl enable jenkins
    
    # Wait for Jenkins to start
    print_info "Waiting for Jenkins to start..."
    sleep 10
    
    # Check Jenkins status
    if systemctl is-active --quiet jenkins; then
        print_success "Jenkins is running"
    else
        print_error "Jenkins failed to start"
        systemctl status jenkins
        exit 1
    fi
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    case $OS in
        ubuntu|debian)
            if command -v ufw >/dev/null 2>&1; then
                print_info "Configuring UFW firewall..."
                ufw allow 8080/tcp
                print_success "Firewall configured"
            fi
            ;;
        
        centos|rhel|amzn)
            if command -v firewall-cmd >/dev/null 2>&1; then
                print_info "Configuring firewalld..."
                firewall-cmd --permanent --add-port=8080/tcp
                firewall-cmd --reload
                print_success "Firewall configured"
            fi
            ;;
    esac
}

# Get initial admin password
get_admin_password() {
    print_header "Jenkins Initial Setup"
    
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        ADMIN_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        
        echo ""
        print_success "Jenkins is ready!"
        echo ""
        print_info "=========================================="
        print_info "Access Jenkins at: http://localhost:8080"
        print_info "Or: http://$(hostname -I | awk '{print $1}'):8080"
        print_info "=========================================="
        echo ""
        print_warning "Initial Admin Password:"
        echo -e "${GREEN}${ADMIN_PASSWORD}${NC}"
        echo ""
        print_info "=========================================="
        echo ""
        print_info "Next Steps:"
        print_info "1. Open Jenkins in your browser"
        print_info "2. Enter the initial admin password above"
        print_info "3. Install suggested plugins"
        print_info "4. Create your admin user"
        print_info "5. Install additional plugins from jenkins/plugins.txt"
        echo ""
    else
        print_warning "Initial admin password file not found"
        print_info "Jenkins may still be starting up. Wait a moment and check:"
        print_info "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
}

# Install Jenkins plugins
install_plugins() {
    print_header "Installing Jenkins Plugins"
    
    print_info "To install required plugins:"
    print_info "1. Go to Manage Jenkins → Manage Plugins"
    print_info "2. Click 'Available' tab"
    print_info "3. Install these plugins:"
    echo ""
    cat jenkins/plugins.txt
    echo ""
    print_info "Or use Jenkins CLI to install automatically"
}

# Display summary
display_summary() {
    print_header "Installation Summary"
    
    echo ""
    print_success "Jenkins Installation Complete!"
    echo ""
    print_info "Service Status:"
    systemctl status jenkins --no-pager | head -n 5
    echo ""
    print_info "Jenkins URL: http://localhost:8080"
    print_info "Jenkins Home: /var/lib/jenkins"
    print_info "Jenkins Logs: /var/log/jenkins/jenkins.log"
    echo ""
    print_info "Useful Commands:"
    print_info "  Start:   sudo systemctl start jenkins"
    print_info "  Stop:    sudo systemctl stop jenkins"
    print_info "  Restart: sudo systemctl restart jenkins"
    print_info "  Status:  sudo systemctl status jenkins"
    print_info "  Logs:    sudo journalctl -u jenkins -f"
    echo ""
}

# Main execution
main() {
    print_header "Jenkins Installation Script"
    echo ""
    
    # Detect OS
    detect_os
    echo ""
    
    # Install Java
    if ! command -v java >/dev/null 2>&1; then
        install_java
    else
        print_success "Java is already installed"
    fi
    echo ""
    
    # Install Jenkins
    if ! command -v jenkins >/dev/null 2>&1; then
        install_jenkins
    else
        print_success "Jenkins is already installed"
    fi
    echo ""
    
    # Start Jenkins
    start_jenkins
    echo ""
    
    # Configure firewall
    configure_firewall
    echo ""
    
    # Get admin password
    get_admin_password
    
    # Display summary
    display_summary
    
    print_success "Setup completed successfully!"
}

# Run main function
main
