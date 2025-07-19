# Frontend Setup Guide

## Overview

The frontend is built with React.js and provides a modern, responsive user interface for the Get Paid to Play Ecosystem. This guide will help you set up the development environment and understand the frontend architecture.

## Prerequisites

- Node.js 16.x or higher
- npm or yarn package manager
- Git

## Installation

### 1. Navigate to Frontend Directory

```bash
cd frontend
```

### 2. Install Dependencies

```bash
npm install
# or
yarn install
```

### 3. Environment Configuration

Create a `.env` file in the frontend directory:

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration:

```env
# API Configuration
REACT_APP_API_URL=http://localhost:5000/api/v1
REACT_APP_WS_URL=ws://localhost:5000

# Discord Configuration
REACT_APP_DISCORD_CLIENT_ID=your-discord-client-id
REACT_APP_DISCORD_REDIRECT_URI=http://localhost:3000/auth/discord/callback

# Payment Configuration
REACT_APP_PAYPAL_CLIENT_ID=your-paypal-client-id

# App Configuration
REACT_APP_NAME=Get Paid to Play
REACT_APP_VERSION=1.0.0
REACT_APP_ENVIRONMENT=development
```

## Project Structure

```
frontend/
├── public/
│   ├── index.html
│   ├── favicon.ico
│   └── manifest.json
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── common/
│   │   │   ├── Header.js
│   │   │   ├── Footer.js
│   │   │   ├── Loading.js
│   │   │   └── ErrorBoundary.js
│   │   ├── auth/
│   │   │   ├── LoginForm.js
│   │   │   ├── RegisterForm.js
│   │   │   └── DiscordAuth.js
│   │   ├── leaderboard/
│   │   │   ├── LeaderboardTable.js
│   │   │   ├── LeaderboardFilters.js
│   │   │   └── PlayerCard.js
│   │   ├── dashboard/
│   │   │   ├── UserStats.js
│   │   │   ├── RecentGames.js
│   │   │   └── EarningsChart.js
│   │   └── games/
│   │       ├── GameCard.js
│   │       ├── GameSession.js
│   │       └── GameHistory.js
│   ├── pages/               # Page components
│   │   ├── Home.js
│   │   ├── Dashboard.js
│   │   ├── Leaderboard.js
│   │   ├── Games.js
│   │   ├── Profile.js
│   │   ├── Rewards.js
│   │   └── Auth.js
│   ├── hooks/               # Custom React hooks
│   │   ├── useAuth.js
│   │   ├── useApi.js
│   │   ├── useWebSocket.js
│   │   └── useLocalStorage.js
│   ├── services/            # API and external services
│   │   ├── api.js
│   │   ├── auth.js
│   │   ├── websocket.js
│   │   └── discord.js
│   ├── store/               # State management (Redux/Context)
│   │   ├── index.js
│   │   ├── authSlice.js
│   │   ├── gameSlice.js
│   │   ├── leaderboardSlice.js
│   │   └── userSlice.js
│   ├── utils/               # Utility functions
│   │   ├── constants.js
│   │   ├── helpers.js
│   │   ├── validators.js
│   │   └── formatters.js
│   ├── styles/              # CSS and styling
│   │   ├── globals.css
│   │   ├── components.css
│   │   └── themes.css
│   ├── App.js               # Main App component
│   ├── index.js             # Entry point
│   └── setupTests.js        # Test configuration
├── package.json             # Dependencies and scripts
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
└── README.md               # Frontend-specific documentation
```

## Running the Application

### Development Mode

```bash
npm start
# or
yarn start
```

The application will be available at `http://localhost:3000`

### Production Build

```bash
npm run build
# or
yarn build
```

### Testing

```bash
# Run tests
npm test
# or
yarn test

# Run tests with coverage
npm run test:coverage
# or
yarn test:coverage
```

## Key Features

### Authentication System
- JWT token-based authentication
- Discord OAuth integration
- Persistent login state
- Protected routes

### Real-time Updates
- WebSocket connection for live data
- Real-time leaderboard updates
- Live game session tracking
- Instant notifications

### Responsive Design
- Mobile-first approach
- Tablet and desktop optimization
- Touch-friendly interface
- Accessibility compliance

### State Management
- Redux Toolkit for global state
- React Context for theme/settings
- Local storage for persistence
- Optimistic updates

## Component Architecture

### Common Components

#### Header Component
```jsx
import React from 'react';
import { useAuth } from '../hooks/useAuth';

const Header = () => {
  const { user, logout } = useAuth();
  
  return (
    <header className="app-header">
      <div className="logo">Get Paid to Play</div>
      <nav>
        {user ? (
          <UserMenu user={user} onLogout={logout} />
        ) : (
          <AuthButtons />
        )}
      </nav>
    </header>
  );
};
```

#### Leaderboard Table
```jsx
import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchLeaderboard } from '../store/leaderboardSlice';

const LeaderboardTable = ({ gameId, period }) => {
  const dispatch = useDispatch();
  const { data, loading, error } = useSelector(state => state.leaderboard);
  
  useEffect(() => {
    dispatch(fetchLeaderboard({ gameId, period }));
  }, [dispatch, gameId, period]);
  
  if (loading) return <Loading />;
  if (error) return <Error message={error} />;
  
  return (
    <table className="leaderboard-table">
      <thead>
        <tr>
          <th>Rank</th>
          <th>Player</th>
          <th>Score</th>
          <th>Earnings</th>
        </tr>
      </thead>
      <tbody>
        {data.map((player, index) => (
          <PlayerRow key={player.id} player={player} rank={index + 1} />
        ))}
      </tbody>
    </table>
  );
};
```

### Custom Hooks

#### useAuth Hook
```jsx
import { useSelector, useDispatch } from 'react-redux';
import { login, logout, register } from '../store/authSlice';

export const useAuth = () => {
  const dispatch = useDispatch();
  const { user, token, loading, error } = useSelector(state => state.auth);
  
  const handleLogin = async (credentials) => {
    return dispatch(login(credentials));
  };
  
  const handleLogout = () => {
    dispatch(logout());
  };
  
  const handleRegister = async (userData) => {
    return dispatch(register(userData));
  };
  
  return {
    user,
    token,
    loading,
    error,
    isAuthenticated: !!token,
    login: handleLogin,
    logout: handleLogout,
    register: handleRegister
  };
};
```

#### useWebSocket Hook
```jsx
import { useEffect, useRef } from 'react';
import { useDispatch } from 'react-redux';

export const useWebSocket = (url, token) => {
  const ws = useRef(null);
  const dispatch = useDispatch();
  
  useEffect(() => {
    if (token) {
      ws.current = new WebSocket(`${url}?token=${token}`);
      
      ws.current.onmessage = (event) => {
        const data = JSON.parse(event.data);
        // Dispatch appropriate actions based on message type
        switch (data.type) {
          case 'LEADERBOARD_UPDATE':
            dispatch(updateLeaderboard(data.payload));
            break;
          case 'GAME_SESSION_UPDATE':
            dispatch(updateGameSession(data.payload));
            break;
          default:
            console.log('Unknown message type:', data.type);
        }
      };
      
      return () => {
        ws.current?.close();
      };
    }
  }, [url, token, dispatch]);
  
  const sendMessage = (message) => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(message));
    }
  };
  
  return { sendMessage };
};
```

## Styling and Theming

### CSS Variables
```css
:root {
  --primary-color: #6366f1;
  --secondary-color: #8b5cf6;
  --success-color: #10b981;
  --warning-color: #f59e0b;
  --error-color: #ef4444;
  --background-color: #f8fafc;
  --surface-color: #ffffff;
  --text-primary: #1f2937;
  --text-secondary: #6b7280;
  --border-color: #e5e7eb;
  --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
}
```

### Component Styling
```css
.leaderboard-table {
  width: 100%;
  border-collapse: collapse;
  background: var(--surface-color);
  border-radius: 8px;
  overflow: hidden;
  box-shadow: var(--shadow);
}

.leaderboard-table th {
  background: var(--primary-color);
  color: white;
  padding: 1rem;
  text-align: left;
  font-weight: 600;
}

.leaderboard-table td {
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.leaderboard-table tr:hover {
  background: #f8fafc;
}
```

## API Integration

### API Service
```javascript
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL;

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

// Request interceptor to add auth token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/auth';
    }
    return Promise.reject(error);
  }
);

export default api;
```

## Performance Optimization

### Code Splitting
```jsx
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const Leaderboard = lazy(() => import('./pages/Leaderboard'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/leaderboard" element={<Leaderboard />} />
      </Routes>
    </Suspense>
  );
}
```

### Memoization
```jsx
import { memo, useMemo } from 'react';

const PlayerCard = memo(({ player }) => {
  const formattedEarnings = useMemo(() => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(player.earnings);
  }, [player.earnings]);
  
  return (
    <div className="player-card">
      <h3>{player.username}</h3>
      <p>Earnings: {formattedEarnings}</p>
    </div>
  );
});
```

## Testing

### Component Testing
```jsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Provider } from 'react-redux';
import { store } from '../store';
import LoginForm from '../components/auth/LoginForm';

test('renders login form', () => {
  render(
    <Provider store={store}>
      <LoginForm />
    </Provider>
  );
  
  expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
});

test('submits form with valid data', async () => {
  const mockLogin = jest.fn();
  
  render(
    <Provider store={store}>
      <LoginForm onLogin={mockLogin} />
    </Provider>
  );
  
  fireEvent.change(screen.getByLabelText(/email/i), {
    target: { value: 'test@example.com' }
  });
  
  fireEvent.change(screen.getByLabelText(/password/i), {
    target: { value: 'password123' }
  });
  
  fireEvent.click(screen.getByRole('button', { name: /login/i }));
  
  expect(mockLogin).toHaveBeenCalledWith({
    email: 'test@example.com',
    password: 'password123'
  });
});
```

## Deployment

### Build for Production
```bash
npm run build
```

### Environment Variables for Production
```env
REACT_APP_API_URL=https://api.getpaidtoplay.com/api/v1
REACT_APP_WS_URL=wss://api.getpaidtoplay.com
REACT_APP_ENVIRONMENT=production
```

## Troubleshooting

### Common Issues

1. **CORS errors**
   - Ensure backend CORS is configured correctly
   - Check API_URL in .env file

2. **WebSocket connection issues**
   - Verify WS_URL configuration
   - Check network connectivity

3. **Build errors**
   - Clear node_modules and reinstall: `rm -rf node_modules && npm install`
   - Check for TypeScript errors if using TypeScript

4. **Performance issues**
   - Use React DevTools Profiler
   - Check for unnecessary re-renders
   - Implement proper memoization

## Next Steps

1. Set up backend API
2. Configure Discord integration
3. Implement payment processing
4. Set up deployment pipeline

For more information, see the [API Documentation](api.md) and [Backend Setup Guide](backend-setup.md).

