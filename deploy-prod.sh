#!/bin/bash

# FastAPI Production Deployment Script
# This script helps deploy the FastAPI application in production

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="flasx"
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.prod"
BACKUP_DIR="backups"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are met."
}

# Function to setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f ".env.prod.template" ]; then
            print_warning ".env.prod not found. Copying from template..."
            cp .env.prod.template "$ENV_FILE"
            print_warning "Please edit $ENV_FILE with your production values before continuing."
            print_warning "Pay special attention to SECRET_KEY and JWT_SECRET_KEY values."
            exit 1
        else
            print_error ".env.prod not found and no template available."
            exit 1
        fi
    fi
    
    # Create necessary directories
    mkdir -p data logs nginx/ssl "$BACKUP_DIR"
    
    # Set proper permissions
    chmod 755 data logs
    chmod 700 nginx/ssl
    
    print_success "Environment setup completed."
}

# Function to generate SSL certificates (self-signed for development)
generate_ssl_certs() {
    print_status "Checking SSL certificates..."
    
    if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
        print_warning "SSL certificates not found. Generating self-signed certificates..."
        print_warning "For production, replace these with proper SSL certificates."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        chmod 600 nginx/ssl/key.pem
        chmod 644 nginx/ssl/cert.pem
        
        print_success "Self-signed SSL certificates generated."
    else
        print_success "SSL certificates found."
    fi
}

# Function to backup database
backup_database() {
    if [ -f "data/database.db" ]; then
        print_status "Creating database backup..."
        timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "data/database.db" "$BACKUP_DIR/database_backup_$timestamp.db"
        print_success "Database backed up to $BACKUP_DIR/database_backup_$timestamp.db"
    fi
}

# Function to build and deploy
deploy() {
    print_status "Building and deploying $PROJECT_NAME..."
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
    fi
    
    # Build the image
    print_status "Building Docker image..."
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    # Start services
    print_status "Starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        print_success "Deployment completed successfully!"
        print_status "Services status:"
        docker-compose -f "$COMPOSE_FILE" ps
    else
        print_error "Some services failed to start. Check logs:"
        docker-compose -f "$COMPOSE_FILE" logs
        exit 1
    fi
}

# Function to show logs
show_logs() {
    print_status "Showing logs for $PROJECT_NAME..."
    docker-compose -f "$COMPOSE_FILE" logs -f
}

# Function to stop services
stop_services() {
    print_status "Stopping services..."
    docker-compose -f "$COMPOSE_FILE" down
    print_success "Services stopped."
}

# Function to restart services
restart_services() {
    print_status "Restarting services..."
    docker-compose -f "$COMPOSE_FILE" restart
    print_success "Services restarted."
}

# Function to show status
show_status() {
    print_status "Service status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    print_status "Health check:"
    if command_exists curl; then
        curl -f http://localhost:8000/health && echo
    else
        print_warning "curl not found. Please check http://localhost:8000/health manually."
    fi
}

# Function to clean up
cleanup() {
    print_status "Cleaning up..."
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    docker system prune -f
    print_success "Cleanup completed."
}

# Function to show help
show_help() {
    echo "FastAPI Production Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Deploy the application (default)"
    echo "  logs       - Show application logs"
    echo "  status     - Show service status"
    echo "  stop       - Stop all services"
    echo "  restart    - Restart all services"
    echo "  backup     - Backup database"
    echo "  cleanup    - Stop services and clean up"
    echo "  help       - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 logs"
    echo "  $0 status"
}

# Main execution
main() {
    local command="${1:-deploy}"
    
    case "$command" in
        deploy)
            check_prerequisites
            setup_environment
            generate_ssl_certs
            backup_database
            deploy
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        backup)
            backup_database
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
