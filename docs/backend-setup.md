# Backend Setup Guide

## Overview

The backend is built with Python Flask and provides a RESTful API for the Get Paid to Play Ecosystem. This guide will help you set up the development environment and understand the backend architecture.

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- PostgreSQL (for production) or SQLite (for development)
- Redis (for caching and sessions)

## Installation

### 1. Navigate to Backend Directory

```bash
cd backend
```

### 2. Create Virtual Environment

```bash
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Environment Configuration

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration:

```env
# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-here

# Database Configuration
DATABASE_URL=sqlite:///app.db
# For PostgreSQL: postgresql://username:password@localhost/dbname

# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key
JWT_ACCESS_TOKEN_EXPIRES=3600

# Discord Configuration
DISCORD_BOT_TOKEN=your-discord-bot-token
DISCORD_CLIENT_ID=your-discord-client-id
DISCORD_CLIENT_SECRET=your-discord-client-secret

# Payment Configuration
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-client-secret
PAYPAL_MODE=sandbox  # or live for production

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

### 5. Database Setup

```bash
# Initialize database
python manage.py db init

# Create migration
python manage.py db migrate -m "Initial migration"

# Apply migration
python manage.py db upgrade

# Seed database with sample data (optional)
python manage.py seed
```

## Project Structure

```
backend/
├── app/
│   ├── __init__.py          # Flask app factory
│   ├── models/              # Database models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── game.py
│   │   ├── session.py
│   │   ├── leaderboard.py
│   │   └── reward.py
│   ├── api/                 # API routes
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── users.py
│   │   ├── games.py
│   │   ├── leaderboards.py
│   │   └── rewards.py
│   ├── services/            # Business logic
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── game_service.py
│   │   ├── leaderboard_service.py
│   │   ├── reward_service.py
│   │   └── discord_service.py
│   ├── utils/               # Utility functions
│   │   ├── __init__.py
│   │   ├── decorators.py
│   │   ├── validators.py
│   │   └── helpers.py
│   └── config.py            # Configuration classes
├── migrations/              # Database migrations
├── tests/                   # Test files
├── requirements.txt         # Python dependencies
├── .env.example            # Environment variables template
├── manage.py               # Management commands
└── run.py                  # Application entry point
```

## Running the Application

### Development Mode

```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Run the development server
python run.py

# Or use Flask CLI
export FLASK_APP=run.py
flask run
```

The API will be available at `http://localhost:5000`

### Production Mode

```bash
# Install production server
pip install gunicorn

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 run:app
```

## Database Models

### User Model
- `id`: Primary key
- `username`: Unique username
- `email`: Unique email address
- `password_hash`: Hashed password
- `discord_id`: Discord user ID (optional)
- `total_earnings`: Total rewards earned
- `is_active`: Account status
- `created_at`: Registration timestamp

### Game Model
- `id`: Primary key
- `name`: Game name
- `description`: Game description
- `reward_rate`: Reward per point/minute
- `is_active`: Game availability status

### GameSession Model
- `id`: Primary key
- `user_id`: Foreign key to User
- `game_id`: Foreign key to Game
- `score`: Final score
- `duration`: Session duration in seconds
- `earnings`: Calculated earnings
- `started_at`: Session start time
- `ended_at`: Session end time

### Reward Model
- `id`: Primary key
- `user_id`: Foreign key to User
- `amount`: Reward amount
- `reason`: Reason for reward
- `status`: pending/completed/failed
- `payment_method`: Payment method used
- `created_at`: Reward creation time
- `processed_at`: Payment processing time

## API Testing

### Using curl

```bash
# Register a new user
curl -X POST http://localhost:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get profile (replace TOKEN with actual JWT token)
curl -X GET http://localhost:5000/api/v1/users/profile \
  -H "Authorization: Bearer TOKEN"
```

### Using Python requests

```python
import requests

# Base URL
base_url = "http://localhost:5000/api/v1"

# Register user
response = requests.post(f"{base_url}/auth/register", json={
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
})

# Login
response = requests.post(f"{base_url}/auth/login", json={
    "email": "test@example.com",
    "password": "password123"
})

token = response.json()["token"]

# Get profile
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(f"{base_url}/users/profile", headers=headers)
```

## Common Commands

```bash
# Create new migration
python manage.py db migrate -m "Description of changes"

# Apply migrations
python manage.py db upgrade

# Rollback migration
python manage.py db downgrade

# Create admin user
python manage.py create-admin

# Seed database
python manage.py seed

# Run tests
python -m pytest tests/

# Check code style
flake8 app/

# Format code
black app/
```

## Troubleshooting

### Common Issues

1. **Database connection errors**
   - Check DATABASE_URL in .env file
   - Ensure PostgreSQL is running (if using PostgreSQL)
   - Verify database exists and user has permissions

2. **Import errors**
   - Ensure virtual environment is activated
   - Check if all dependencies are installed: `pip install -r requirements.txt`

3. **JWT token errors**
   - Verify JWT_SECRET_KEY is set in .env
   - Check token expiration settings

4. **Discord integration issues**
   - Verify Discord bot token and permissions
   - Check Discord application settings

### Logging

Logs are configured in `app/config.py`. Check the logs for detailed error information:

```bash
# View logs in development
tail -f logs/app.log
```

## Next Steps

1. Set up the frontend application
2. Configure Discord bot
3. Set up payment processing
4. Deploy to production environment

For more information, see the [API Documentation](api.md) and [Discord Setup Guide](discord-setup.md).

