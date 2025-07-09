#!/bin/bash

# FastAPI Development Environment Management Script
# This script helps manage the development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="flasx-dev"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env.dev"

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

# Function to setup development environment
setup_dev_env() {
    print_status "Setting up development environment..."
    
    # Create necessary directories
    mkdir -p data logs config monitoring/grafana/{datasources,dashboards}
    
    # Set proper permissions
    chmod 755 data logs
    
    print_success "Development environment setup completed."
}

# Function to start development services
start_dev() {
    print_status "Starting development services..."
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
    fi
    
    # Start core services
    docker-compose -f "$COMPOSE_FILE" up -d flasx-dev db redis
    
    print_success "Core development services started!"
    print_status "Services status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    print_status "FastAPI app available at: http://localhost:8000"
    print_status "API docs available at: http://localhost:8000/docs"
    print_status "Alternative docs at: http://localhost:8000/redoc"
}

# Function to start all services including tools
start_all() {
    print_status "Starting all development services and tools..."
    
    docker-compose -f "$COMPOSE_FILE" --profile tools --profile monitoring up -d
    
    print_success "All development services started!"
    show_services_info
}

# Function to show services information
show_services_info() {
    print_status "Development services information:"
    echo "🚀 FastAPI App:      http://localhost:8000"
    echo "📚 API Docs:         http://localhost:8000/docs"
    echo "📖 ReDoc:            http://localhost:8000/redoc"
    echo "🗄️  PostgreSQL:      localhost:5432 (flasx_user/flasx_password)"
    echo "🔴 Redis:            localhost:6379"
    echo "🐘 pgAdmin:          http://localhost:5050 (admin@flasx.local/admin123)"
    echo "🔧 Redis Commander:  http://localhost:8081 (admin/admin123)"
    echo "📧 Mailhog:          http://localhost:8025"
    echo "📊 Prometheus:       http://localhost:9090"
    echo "📈 Grafana:          http://localhost:3000 (admin/admin123)"
}

# Function to stop services
stop_dev() {
    print_status "Stopping development services..."
    docker-compose -f "$COMPOSE_FILE" down
    print_success "Development services stopped."
}

# Function to restart services
restart_dev() {
    print_status "Restarting development services..."
    docker-compose -f "$COMPOSE_FILE" restart
    print_success "Development services restarted."
}

# Function to show logs
show_logs() {
    local service="${1:-flasx-dev}"
    print_status "Showing logs for $service..."
    docker-compose -f "$COMPOSE_FILE" logs -f "$service"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    docker-compose -f "$COMPOSE_FILE" --profile test run --rm test-runner
}

# Function to access shell
shell() {
    local service="${1:-flasx-dev}"
    print_status "Opening shell in $service..."
    docker-compose -f "$COMPOSE_FILE" exec "$service" bash
}

# Function to reset development environment
reset_dev() {
    print_warning "This will remove all containers, volumes, and data. Are you sure? (y/N)"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            print_status "Resetting development environment..."
            docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
            docker system prune -f
            # Recreate directories
            rm -rf data logs
            setup_dev_env
            print_success "Development environment reset completed."
            ;;
        *)
            print_status "Reset cancelled."
            ;;
    esac
}

# Function to show status
show_status() {
    print_status "Development services status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    print_status "Health checks:"
    if command_exists curl; then
        echo -n "FastAPI Health: "
        if curl -f -s http://localhost:8000/health >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Healthy${NC}"
        else
            echo -e "${RED}✗ Unhealthy${NC}"
        fi
        
        echo -n "PostgreSQL: "
        if docker-compose -f "$COMPOSE_FILE" exec -T db pg_isready -U flasx_user >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Ready${NC}"
        else
            echo -e "${RED}✗ Not Ready${NC}"
        fi
        
        echo -n "Redis: "
        if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${RED}✗ Not Connected${NC}"
        fi
    else
        print_warning "curl not found. Please check services manually."
    fi
}

# Function to show help
show_help() {
    echo "FastAPI Development Environment Management Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start       - Start core development services (FastAPI, DB, Redis)"
    echo "  start-all   - Start all services including tools and monitoring"
    echo "  stop        - Stop all development services"
    echo "  restart     - Restart development services"
    echo "  logs [SVC]  - Show logs for service (default: flasx-dev)"
    echo "  status      - Show service status and health"
    echo "  test        - Run tests"
    echo "  shell [SVC] - Open shell in service (default: flasx-dev)"
    echo "  reset       - Reset entire development environment"
    echo "  info        - Show services information"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs flasx-dev"
    echo "  $0 shell db"
    echo "  $0 test"
}

# Main execution
main() {
    local command="${1:-start}"
    local option="${2:-}"
    
    case "$command" in
        start)
            check_prerequisites
            setup_dev_env
            start_dev
            ;;
        start-all)
            check_prerequisites
            setup_dev_env
            start_all
            ;;
        stop)
            stop_dev
            ;;
        restart)
            restart_dev
            ;;
        logs)
            show_logs "$option"
            ;;
        status)
            show_status
            ;;
        test)
            run_tests
            ;;
        shell)
            shell "$option"
            ;;
        reset)
            reset_dev
            ;;
        info)
            show_services_info
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
