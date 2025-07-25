# Quick Reference Guide - GPTP Development

## 🚀 Getting Started

### Prerequisites
```bash
# Required software
- Node.js 18+
- Python 3.9+
- PostgreSQL 13+
- Redis 6+
- Docker & Docker Compose
```

### Quick Setup
```bash
# Clone and setup
git clone https://github.com/NemeanGames/get-paid-to-play-ecosystem.git
cd get-paid-to-play-ecosystem
./scripts/setup.sh

# Start development environment
docker-compose up -d

# Access services
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000
# Database: localhost:5432
```

---

## 📱 Platform Quick Start

### Web Game Development
```javascript
// Basic web game setup
import { GPTPClient } from '@gptp/web-sdk';

const client = new GPTPClient(API_KEY, USER_ID);

// Start game
const session = await client.startGameSession('my-game');

// Update score
await client.updateScore(1000);

// End game
const result = await client.endGameSession({
    finalScore: 1000,
    duration: 120000
});
```

### Android Game Development
```kotlin
// Basic Android integration
class MainActivity : AppCompatActivity() {
    private lateinit var gptpClient: GPTPClient
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        gptpClient = GPTPClient(API_KEY, USER_ID)
        
        lifecycleScope.launch {
            val session = gptpClient.startGameSession("my-game")
            // Game logic here
        }
    }
}
```

### iOS Game Development
```swift
// Basic iOS integration
class GameViewController: UIViewController {
    private var gptpClient: GPTPClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gptpClient = GPTPClient(apiKey: API_KEY, userId: USER_ID)
        
        Task {
            let session = try await gptpClient.startGameSession(gameId: "my-game")
            // Game logic here
        }
    }
}
```

---

## 🔧 API Quick Reference

### Authentication
```bash
# Register user
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"player1","email":"player1@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"player1@example.com","password":"password123"}'
```

### Game Sessions
```bash
# Start game session
curl -X POST http://localhost:5000/api/games/session/start \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"game_id":"snake-game"}'

# Update score
curl -X PUT http://localhost:5000/api/games/session/SESSION_ID/score \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"score":1500}'

# End session
curl -X POST http://localhost:5000/api/games/session/SESSION_ID/end \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"final_score":1500,"duration":120000}'
```

### Leaderboards
```bash
# Get leaderboard
curl -X GET http://localhost:5000/api/leaderboard/snake-game \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get user stats
curl -X GET http://localhost:5000/api/user/stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🎮 Game Development Templates

### Phaser.js Game Template
```javascript
class GameScene extends Phaser.Scene {
    constructor() {
        super({ key: 'GameScene' });
        this.gptpClient = null;
        this.score = 0;
    }
    
    async create() {
        // Initialize GPTP
        this.gptpClient = new GPTPClient(API_KEY, USER_ID);
        await this.gptpClient.startGameSession('my-game');
        
        // Game setup
        this.setupGame();
        this.setupUI();
        this.setupInput();
    }
    
    setupGame() {
        // Game objects initialization
    }
    
    setupUI() {
        this.scoreText = this.add.text(16, 16, 'Score: 0', {
            fontSize: '32px',
            fill: '#000'
        });
    }
    
    updateScore(points) {
        this.score += points;
        this.scoreText.setText('Score: ' + this.score);
        this.gptpClient.updateScore(this.score);
    }
    
    async gameOver() {
        const result = await this.gptpClient.endGameSession({
            finalScore: this.score,
            duration: this.time.now
        });
        
        // Show game over screen with earnings
        this.showGameOverScreen(result);
    }
}
```

### Unity C# Template
```csharp
using UnityEngine;
using System.Threading.Tasks;

public class GPTPGameManager : MonoBehaviour
{
    private GPTPClient gptpClient;
    private int currentScore = 0;
    
    async void Start()
    {
        gptpClient = new GPTPClient(API_KEY, USER_ID);
        await gptpClient.StartGameSession("my-unity-game");
    }
    
    public async void UpdateScore(int points)
    {
        currentScore += points;
        await gptpClient.UpdateScore(currentScore);
        
        // Update UI
        ScoreUI.Instance.UpdateScore(currentScore);
    }
    
    public async void EndGame()
    {
        var result = await gptpClient.EndGameSession(new GameEndData
        {
            FinalScore = currentScore,
            Duration = Time.time
        });
        
        // Show results
        GameOverUI.Instance.ShowResults(result);
    }
}
```

---

## 🗄️ Database Quick Reference

### Common Queries
```sql
-- Get user stats
SELECT 
    u.username,
    COUNT(gs.id) as games_played,
    SUM(gs.final_score) as total_score,
    SUM(gs.earnings) as total_earnings
FROM users u
LEFT JOIN game_sessions gs ON u.id = gs.user_id
WHERE u.id = ?
GROUP BY u.id;

-- Get leaderboard
SELECT 
    u.username,
    l.high_score,
    l.total_earnings,
    l.last_played
FROM leaderboard l
JOIN users u ON l.user_id = u.id
WHERE l.game_id = ?
ORDER BY l.high_score DESC
LIMIT 50;

-- Get recent game sessions
SELECT 
    gs.id,
    g.name as game_name,
    gs.final_score,
    gs.earnings,
    gs.created_at
FROM game_sessions gs
JOIN games g ON gs.game_id = g.id
WHERE gs.user_id = ?
ORDER BY gs.created_at DESC
LIMIT 20;
```

### Database Migrations
```python
# Example migration
from flask_migrate import Migrate

# Create migration
flask db migrate -m "Add achievements table"

# Apply migration
flask db upgrade

# Rollback migration
flask db downgrade
```

---

## 🔧 Environment Configuration

### Development Environment Variables
```bash
# .env.development
FLASK_ENV=development
DATABASE_URL=postgresql://user:pass@localhost:5432/gptp_dev
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=dev-secret-key
PAYPAL_CLIENT_ID=your-paypal-sandbox-client-id
PAYPAL_CLIENT_SECRET=your-paypal-sandbox-secret
DISCORD_BOT_TOKEN=your-discord-bot-token
DISCORD_WEBHOOK_URL=your-discord-webhook-url
```

### Production Environment Variables
```bash
# .env.production
FLASK_ENV=production
DATABASE_URL=postgresql://user:pass@prod-db:5432/gptp_prod
REDIS_URL=redis://prod-redis:6379/0
JWT_SECRET_KEY=super-secure-production-key
PAYPAL_CLIENT_ID=your-paypal-live-client-id
PAYPAL_CLIENT_SECRET=your-paypal-live-secret
DISCORD_BOT_TOKEN=your-discord-bot-token
DISCORD_WEBHOOK_URL=your-discord-webhook-url
```

---

## 🧪 Testing Quick Reference

### Backend Testing
```python
# Test game session creation
def test_start_game_session(client, auth_headers):
    response = client.post('/api/games/session/start', 
                          json={'game_id': 'test-game'},
                          headers=auth_headers)
    assert response.status_code == 201
    assert 'session_id' in response.json

# Test score update
def test_update_score(client, auth_headers, game_session):
    response = client.put(f'/api/games/session/{game_session.id}/score',
                         json={'score': 1000},
                         headers=auth_headers)
    assert response.status_code == 200
```

### Frontend Testing
```javascript
// Test game component
import { render, screen } from '@testing-library/react';
import GameComponent from './GameComponent';

test('renders game score', () => {
    render(<GameComponent initialScore={0} />);
    const scoreElement = screen.getByText(/score: 0/i);
    expect(scoreElement).toBeInTheDocument();
});

// Test API integration
test('starts game session', async () => {
    const mockClient = {
        startGameSession: jest.fn().mockResolvedValue({ sessionId: 'test-123' })
    };
    
    const result = await mockClient.startGameSession('test-game');
    expect(result.sessionId).toBe('test-123');
});
```

---

## 🚀 Deployment Quick Reference

### Docker Commands
```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Reset database
docker-compose down -v
docker-compose up -d postgres
docker-compose exec backend flask db upgrade
```

### Production Deployment
```bash
# Deploy to production
git push origin main

# Manual deployment
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Database migration in production
docker-compose exec backend flask db upgrade

# Check service health
curl https://api.yoursite.com/health
```

---

## 🐛 Troubleshooting

### Common Issues

#### Database Connection Error
```bash
# Check database status
docker-compose ps postgres

# Reset database
docker-compose down postgres
docker volume rm gptp_postgres_data
docker-compose up -d postgres
```

#### API Authentication Error
```bash
# Check JWT token
curl -X GET http://localhost:5000/api/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -v

# Generate new token
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}'
```

#### Game Loading Issues
```javascript
// Check GPTP client initialization
console.log('API Key:', process.env.REACT_APP_GPTP_API_KEY);
console.log('User ID:', getCurrentUserId());

// Verify API endpoint
fetch('/api/health')
  .then(response => response.json())
  .then(data => console.log('API Health:', data));
```

### Performance Issues
```bash
# Check Redis connection
redis-cli ping

# Monitor database queries
docker-compose exec postgres psql -U user -d gptp_dev -c "SELECT * FROM pg_stat_activity;"

# Check API response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:5000/api/games
```

---

## 📚 Useful Commands

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-game

# Commit changes
git add .
git commit -m "feat: add new puzzle game"

# Push and create PR
git push origin feature/new-game
```

### Database Management
```bash
# Backup database
pg_dump gptp_dev > backup.sql

# Restore database
psql gptp_dev < backup.sql

# Reset development data
flask db downgrade base
flask db upgrade
flask seed-data
```

### Log Analysis
```bash
# View application logs
docker-compose logs -f backend | grep ERROR

# View access logs
docker-compose logs nginx | grep "POST /api"

# Monitor real-time logs
tail -f logs/application.log
```

---

## 🔗 Important Links

- **Main Documentation**: [README.md](../README.md)
- **Technology Stack**: [technology-stack.md](./technology-stack.md)
- **Development Roadmap**: [development-roadmap.md](./development-roadmap.md)
- **API Documentation**: [api.md](./api.md)
- **Backend Setup**: [backend-setup.md](./backend-setup.md)
- **Frontend Setup**: [frontend-setup.md](./frontend-setup.md)

---

## 📞 Support

- **Discord**: Join our developer community
- **GitHub Issues**: Report bugs and request features
- **Email**: dev@gptp.com
- **Documentation**: Check the docs/ folder for detailed guides

---

This quick reference provides essential information for developers working on the GPTP ecosystem. Keep this handy for daily development tasks!

