#!/bin/bash

# ==============================================
# Get Paid to Play Ecosystem - Setup Script
# ==============================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    
    local missing_deps=()
    
    if ! command_exists node; then
        missing_deps+=("Node.js")
    fi
    
    if ! command_exists python3; then
        missing_deps+=("Python 3")
    fi
    
    if ! command_exists git; then
        missing_deps+=("Git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Function to setup backend
setup_backend() {
    print_status "Setting up backend..."
    
    cd backend
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Create requirements.txt if it doesn't exist
    if [ ! -f "requirements.txt" ]; then
        print_status "Creating requirements.txt..."
        cat > requirements.txt << EOF
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-Migrate==4.0.5
Flask-JWT-Extended==4.5.3
Flask-CORS==4.0.0
Flask-Mail==0.9.1
Flask-Limiter==3.5.0
SQLAlchemy==2.0.21
psycopg2-binary==2.9.7
redis==5.0.1
celery==5.3.4
discord.py==2.3.2
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0
pytest==7.4.2
pytest-flask==1.2.0
black==23.9.1
flake8==6.1.0
EOF
    fi
    
    # Install dependencies
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating backend .env file..."
        cp ../config/.env.example .env
        print_warning "Please edit backend/.env with your configuration"
    fi
    
    cd ..
    print_success "Backend setup completed"
}

# Function to setup frontend
setup_frontend() {
    print_status "Setting up frontend..."
    
    cd frontend
    
    # Create package.json if it doesn't exist
    if [ ! -f "package.json" ]; then
        print_status "Creating package.json..."
        cat > package.json << EOF
{
  "name": "get-paid-to-play-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@reduxjs/toolkit": "^1.9.7",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-redux": "^8.1.3",
    "react-router-dom": "^6.16.0",
    "react-scripts": "5.0.1",
    "axios": "^1.5.1",
    "socket.io-client": "^4.7.2",
    "@mui/material": "^5.14.15",
    "@mui/icons-material": "^5.14.15",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "recharts": "^2.8.0",
    "date-fns": "^2.30.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0"
  }
}
EOF
    fi
    
    # Install dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating frontend .env file..."
        cat > .env << EOF
REACT_APP_API_URL=http://localhost:5000/api/v1
REACT_APP_WS_URL=ws://localhost:5000
REACT_APP_NAME=Get Paid to Play
REACT_APP_VERSION=1.0.0
REACT_APP_ENVIRONMENT=development
EOF
        print_warning "Please edit frontend/.env with your configuration"
    fi
    
    cd ..
    print_success "Frontend setup completed"
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    # Check if PostgreSQL is running
    if command_exists psql; then
        print_status "PostgreSQL detected. Creating database..."
        
        # Create database (this might fail if database already exists, which is fine)
        createdb getpaidtoplay 2>/dev/null || print_warning "Database might already exist"
        
        print_success "Database setup completed"
    else
        print_warning "PostgreSQL not found. Using SQLite for development."
        print_warning "For production, please install and configure PostgreSQL."
    fi
}

# Function to setup Docker
setup_docker() {
    if command_exists docker && command_exists docker-compose; then
        print_status "Docker detected. Setting up Docker environment..."
        
        # Create Docker network
        docker network create gp2p_network 2>/dev/null || print_warning "Docker network might already exist"
        
        print_success "Docker setup completed"
        print_status "You can now run 'docker-compose up' to start all services"
    else
        print_warning "Docker not found. Skipping Docker setup."
        print_warning "Install Docker and Docker Compose for containerized development."
    fi
}

# Function to create initial project structure
create_project_structure() {
    print_status "Creating additional project structure..."
    
    # Create additional directories
    mkdir -p logs
    mkdir -p uploads
    mkdir -p tests
    
    # Create .gitignore additions
    cat >> .gitignore << EOF

# Additional ignores
logs/
uploads/
*.log
.DS_Store
Thumbs.db
EOF
    
    print_success "Project structure created"
}

# Function to display next steps
display_next_steps() {
    print_success "Setup completed successfully!"
    echo
    print_status "Next steps:"
    echo "1. Edit configuration files:"
    echo "   - backend/.env"
    echo "   - frontend/.env"
    echo
    echo "2. Start the development servers:"
    echo "   Backend:  cd backend && source venv/bin/activate && python run.py"
    echo "   Frontend: cd frontend && npm start"
    echo
    echo "3. Or use Docker:"
    echo "   docker-compose up"
    echo
    echo "4. Visit http://localhost:3000 to see the application"
    echo
    print_status "For more information, see the documentation in the docs/ directory"
}

# Main execution
main() {
    echo "=================================================="
    echo "Get Paid to Play Ecosystem - Setup Script"
    echo "=================================================="
    echo
    
    check_prerequisites
    setup_backend
    setup_frontend
    setup_database
    setup_docker
    create_project_structure
    display_next_steps
}

# Run main function
main "$@"

