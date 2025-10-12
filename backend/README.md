# Qahwat Al Emarat Backend API

Backend API server for the Qahwat Al Emarat coffee ordering mobile application.

## Features

- **User Authentication**: JWT-based authentication with registration and login
- **MongoDB Integration**: Full MongoDB database integration with Mongoose ODM
- **Security**: Password hashing, JWT tokens, CORS, Helmet security headers
- **RESTful API**: Clean REST API endpoints following best practices
- **Error Handling**: Comprehensive error handling and validation
- **Logging**: Request logging with Morgan

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB Atlas
- **ODM**: Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Security**: bcryptjs, Helmet, CORS
- **Validation**: express-validator

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- MongoDB Atlas account (or local MongoDB)
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd qahwat-al-emarat/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   - Copy `.env` file and update the values:
   ```env
   NODE_ENV=development
   PORT=5000
      MONGODB_URI=***REMOVED***your_mongodb_uri_here
   JWT_SECRET=your_jwt_secret_key
   JWT_EXPIRE=7d
   JWT_REFRESH_SECRET=your_refresh_secret_key
   JWT_REFRESH_EXPIRE=30d
   ```

4. **Start the server**
   ```bash
   # Development mode (with auto-restart)
   npm run dev

   # Production mode
   npm start
   ```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (protected)
- `POST /api/auth/refresh` - Refresh access token

### Health Check
- `GET /` - Server status
- `GET /health` - Health check

## Database Models

### User
- User registration and authentication
- Role-based access (customer, admin)
- Profile management

### Coffee
- Coffee product catalog
- Categories, pricing, stock management
- Ratings and reviews

### Order
- Order management
- Guest and authenticated user orders
- Payment and delivery tracking

## Project Structure

```
backend/
├── controllers/     # Route controllers
├── middleware/      # Custom middleware
├── models/         # MongoDB models
├── routes/         # API routes
├── .env            # Environment variables
├── server.js       # Main server file
└── package.json    # Dependencies
```

## Security Features

- **Password Hashing**: bcryptjs with salt rounds
- **JWT Authentication**: Access and refresh tokens
- **CORS Protection**: Configured for frontend origin
- **Helmet Security**: Security headers
- **Input Validation**: express-validator for all inputs
- **Rate Limiting**: Ready for implementation

## Development

### Available Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run tests (to be implemented)

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | development |
| `PORT` | Server port | 5000 |
| `MONGODB_URI` | MongoDB connection string | - |
| `JWT_SECRET` | JWT signing secret | - |
| `JWT_EXPIRE` | JWT expiration time | 7d |
| `JWT_REFRESH_SECRET` | Refresh token secret | - |
| `JWT_REFRESH_EXPIRE` | Refresh token expiration | 30d |

## API Testing

You can test the API using tools like:
- **Postman**
- **Insomnia**
- **curl**

Example registration request:
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "phone": "+971501234567"
  }'
```

## Deployment

The backend is ready for deployment to:
- **Heroku**
- **Vercel**
- **AWS EC2**
- **DigitalOcean**
- **Railway**

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the ISC License.
