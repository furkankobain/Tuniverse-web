# Tuniverse Backend API

Node.js/Express backend server for Tuniverse music social platform.

## Features

- 🔐 Firebase Authentication integration
- 🎵 Music recommendation engine (collaborative & content-based filtering)
- 📊 User statistics and analytics
- 🎭 Mood-based recommendations
- 🔥 Trending tracks
- 💬 Social features (follow, chat, activities)
- 🎧 Spotify API integration
- 🎼 Lyrics service (Genius API)
- ⚡ Caching with node-cache
- 🛡️ Rate limiting and security headers

## Tech Stack

- **Runtime:** Node.js (v18+)
- **Framework:** Express.js
- **Database:** Firebase Firestore
- **Authentication:** Firebase Auth
- **Caching:** node-cache
- **External APIs:** Spotify, Last.fm, Genius

## Getting Started

### Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- Firebase project with Firestore enabled
- Spotify Developer Account
- Genius API Key (optional, for lyrics)
- Last.fm API Key (optional)

### Installation

1. **Clone the repository**
```bash
cd backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure Firebase**

Download your Firebase service account key from Firebase Console:
- Go to Project Settings > Service Accounts
- Click "Generate New Private Key"
- Save as `config/serviceAccountKey.json`

4. **Set up environment variables**

Copy the example env file:
```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```env
NODE_ENV=development
PORT=3000

FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
FIREBASE_PROJECT_ID=your-project-id

SPOTIFY_CLIENT_ID=your-spotify-client-id
SPOTIFY_CLIENT_SECRET=your-spotify-client-secret

GENIUS_ACCESS_TOKEN=your-genius-token
LASTFM_API_KEY=your-lastfm-key

JWT_SECRET=your-secret-key
```

5. **Start the server**

Development mode with auto-reload:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout
- `GET /api/auth/refresh` - Refresh auth token

### Recommendations
- `GET /api/recommendations/personalized` - Get personalized recommendations (requires auth)
- `GET /api/recommendations/trending?timeframe=week&limit=20` - Get trending tracks
- `GET /api/recommendations/genre/:genre?limit=20` - Get recommendations by genre
- `GET /api/recommendations/mood/:mood?limit=20` - Get mood-based recommendations
  - Moods: `happy`, `sad`, `energetic`, `calm`, `party`, `focused`
- `POST /api/recommendations/feedback` - Record recommendation feedback (requires auth)

### Users
- `GET /api/users/:userId` - Get user profile
- `PUT /api/users/:userId` - Update user profile (requires auth)
- `GET /api/users/:userId/stats` - Get user statistics
- `GET /api/users/:userId/following` - Get user's following list
- `GET /api/users/:userId/followers` - Get user's followers

### Tracks
- `GET /api/tracks/:trackId` - Get track details
- `POST /api/tracks/:trackId/listen` - Record track listen (requires auth)
- `POST /api/tracks/:trackId/rate` - Rate a track (requires auth)
- `GET /api/tracks/:trackId/lyrics` - Get track lyrics
- `GET /api/tracks/:trackId/audio-features` - Get audio features

### Playlists
- `GET /api/playlists/:playlistId` - Get playlist details
- `POST /api/playlists` - Create playlist (requires auth)
- `PUT /api/playlists/:playlistId` - Update playlist (requires auth)
- `DELETE /api/playlists/:playlistId` - Delete playlist (requires auth)
- `POST /api/playlists/:playlistId/tracks` - Add track to playlist (requires auth)

### Social
- `POST /api/social/follow/:userId` - Follow a user (requires auth)
- `POST /api/social/unfollow/:userId` - Unfollow a user (requires auth)
- `GET /api/social/activities` - Get activity feed (requires auth)
- `POST /api/social/messages` - Send a message (requires auth)

### Stats
- `GET /api/stats/user/:userId` - Get user statistics
- `GET /api/stats/global` - Get global platform statistics

### Spotify
- `GET /api/spotify/auth` - Initiate Spotify OAuth
- `GET /api/spotify/callback` - Spotify OAuth callback
- `GET /api/spotify/search?q=query&type=track` - Search Spotify
- `GET /api/spotify/currently-playing` - Get currently playing track (requires auth)

## Authentication

Most endpoints require authentication using Firebase ID tokens. Include the token in the Authorization header:

```
Authorization: Bearer <firebase-id-token>
```

## Rate Limiting

The API implements rate limiting to prevent abuse:
- Window: 15 minutes
- Max requests: 100 per window

## Caching

Results are cached for 1 hour by default to improve performance:
- Recommendations
- Trending tracks
- Genre-based recommendations
- Mood-based recommendations

Cache is automatically invalidated when:
- User provides feedback
- User updates preferences
- TTL expires

## Error Handling

All errors return JSON in the following format:
```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

Common HTTP status codes:
- `200` - Success
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests
- `500` - Internal Server Error

## Development

### Running Tests
```bash
npm test
```

### Linting
```bash
npm run lint
```

### Formatting
```bash
npm run format
```

## Deployment

### Using Docker (Recommended)

Build the image:
```bash
docker build -t tuniverse-backend .
```

Run the container:
```bash
docker run -p 3000:3000 --env-file .env tuniverse-backend
```

### Using PM2

Install PM2:
```bash
npm install -g pm2
```

Start the server:
```bash
pm2 start server.js --name tuniverse-backend
```

### Environment Variables for Production

Ensure these are set in production:
```env
NODE_ENV=production
PORT=3000
FIREBASE_DATABASE_URL=<production-url>
JWT_SECRET=<strong-secret>
CORS_ORIGIN=<production-frontend-url>
```

## Performance Optimization

- **Caching:** 1-hour TTL for recommendations
- **Database Indexing:** Ensure Firestore indexes are created
- **Compression:** Gzip compression enabled
- **Connection Pooling:** Firebase Admin SDK handles this automatically

## Security

- Firebase Admin SDK for secure authentication
- CORS configured with specific origins
- Rate limiting per IP
- Helmet.js for security headers
- Input validation with express-validator

## Monitoring

Check server health:
```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-28T11:58:51.000Z",
  "uptime": 12345
}
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

For issues and questions:
- GitHub Issues: https://github.com/furkankobain/Tuniverse/issues
- Email: support@tuniverse.app
