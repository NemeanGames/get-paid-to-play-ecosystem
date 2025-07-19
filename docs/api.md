# API Documentation

## Overview

The Get Paid to Play Ecosystem API provides RESTful endpoints for managing users, games, leaderboards, and rewards. All API endpoints return JSON responses and use standard HTTP status codes.

## Base URL

```
Development: http://localhost:5000/api/v1
Production: https://api.getpaidtoplay.com/v1
```

## Authentication

The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### Authentication

#### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "discord_id": "string (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string",
    "created_at": "datetime"
  }
}
```

#### POST /auth/login
Authenticate user and receive JWT token.

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "success": true,
  "token": "string",
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string"
  }
}
```

### Users

#### GET /users/profile
Get current user's profile information.

**Headers:** Authorization required

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string",
    "discord_id": "string",
    "total_earnings": "decimal",
    "games_played": "integer",
    "rank": "integer",
    "created_at": "datetime"
  }
}
```

#### PUT /users/profile
Update user profile information.

**Headers:** Authorization required

**Request Body:**
```json
{
  "username": "string (optional)",
  "discord_id": "string (optional)"
}
```

### Games

#### GET /games
Get list of available games.

**Response:**
```json
{
  "success": true,
  "games": [
    {
      "id": "integer",
      "name": "string",
      "description": "string",
      "reward_rate": "decimal",
      "active": "boolean"
    }
  ]
}
```

#### POST /games/sessions
Start a new game session.

**Headers:** Authorization required

**Request Body:**
```json
{
  "game_id": "integer"
}
```

**Response:**
```json
{
  "success": true,
  "session": {
    "id": "integer",
    "game_id": "integer",
    "user_id": "integer",
    "started_at": "datetime",
    "status": "active"
  }
}
```

#### PUT /games/sessions/{session_id}/end
End a game session and record results.

**Headers:** Authorization required

**Request Body:**
```json
{
  "score": "integer",
  "duration": "integer",
  "achievements": ["string"]
}
```

### Leaderboards

#### GET /leaderboards
Get leaderboard data.

**Query Parameters:**
- `game_id` (optional): Filter by specific game
- `period` (optional): daily, weekly, monthly, all-time
- `limit` (optional): Number of results (default: 50)

**Response:**
```json
{
  "success": true,
  "leaderboard": [
    {
      "rank": "integer",
      "user": {
        "id": "integer",
        "username": "string"
      },
      "score": "integer",
      "earnings": "decimal",
      "games_played": "integer"
    }
  ],
  "period": "string",
  "total_players": "integer"
}
```

### Rewards

#### GET /rewards/history
Get user's reward history.

**Headers:** Authorization required

**Query Parameters:**
- `limit` (optional): Number of results (default: 20)
- `offset` (optional): Pagination offset

**Response:**
```json
{
  "success": true,
  "rewards": [
    {
      "id": "integer",
      "amount": "decimal",
      "reason": "string",
      "status": "pending|completed|failed",
      "created_at": "datetime",
      "processed_at": "datetime"
    }
  ],
  "total": "integer"
}
```

#### POST /rewards/withdraw
Request reward withdrawal.

**Headers:** Authorization required

**Request Body:**
```json
{
  "amount": "decimal",
  "payment_method": "paypal|crypto|bank",
  "payment_details": {
    "account": "string"
  }
}
```

### Admin Endpoints

#### GET /admin/users
Get all users (admin only).

**Headers:** Authorization required (admin role)

#### POST /admin/rewards/process
Process pending rewards (admin only).

**Headers:** Authorization required (admin role)

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "details": "object (optional)"
  }
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Internal Server Error

## Rate Limiting

API requests are limited to:
- 100 requests per minute for authenticated users
- 20 requests per minute for unauthenticated users

Rate limit headers are included in responses:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

