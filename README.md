# Simple Mart 🛒

A modern full-stack e-commerce application built with Flutter and Express.js.

## 🚀 Quick Start

### Prerequisites
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [MySQL](https://dev.mysql.com/downloads/) (v8.0 or higher)
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd simple_mart_project
   ```

2. **Setup Backend**
   ```bash
   cd backend
   npm install
   ```

3. **Setup Flutter App**
   ```bash
   cd ../simple_mart
   flutter pub get
   ```

4. **Configure Database**
   - Create a `.env` file in the `backend` directory
   - Copy the contents from `.env.example` and update with your MySQL credentials:
   ```env
   DB_HOST=localhost
   DB_USER=your_mysql_username
   DB_PASSWORD=your_mysql_password
   DB_NAME=simple_mart_db
   DB_PORT=3306
   PORT=5000
   NODE_ENV=development
   JWT_SECRET=your_jwt_secret_key_here
   ```

## 🏃‍♂️ Running the Application

### Start the Backend Server
```bash
cd backend
npm start        # Production mode
# OR
npm run dev      # Development mode (auto-restart on changes)
```
The server will start on `http://localhost:5000`

### Start the Flutter App
```bash
cd simple_mart
flutter run      # Run on connected device/emulator
# OR
flutter run -d web    # Run in web browser
# OR
flutter run -d windows    # Run on Windows desktop
```

## 📱 Supported Platforms
- 📱 **Mobile**: iOS, Android
- 🌐 **Web**: Chrome, Firefox, Safari, Edge
- 💻 **Desktop**: Windows, macOS, Linux

## 🛠️ Development Setup

### Backend Development
```bash
cd backend
npm run dev      # Auto-restart on file changes
```

### Flutter Development
```bash
cd simple_mart
flutter run      # Hot reload enabled by default
```

### Database Setup
The application will automatically:
- Create the `simple_mart_db` database if it doesn't exist
- Establish connection pool for optimal performance
- Test database connectivity on startup

## 📋 Project Structure

```
simple_mart_project/
├── backend/                 # Express.js API Server
│   ├── config/
│   │   └── database.js     # MySQL configuration
│   ├── controllers/        # Business logic (to be developed)
│   ├── models/            # Data models (to be developed)
│   ├── routes/            # API routes (to be developed)
│   ├── .env               # Environment variables
│   ├── server.js          # Main server file
│   └── package.json       # Dependencies
├── simple_mart/           # Flutter Application
│   ├── lib/
│   │   ├── main.dart      # App entry point
│   │   ├── screens/       # UI screens (to be developed)
│   │   ├── widgets/       # Reusable components (to be developed)
│   │   └── services/      # API integration (to be developed)
│   └── pubspec.yaml       # Flutter dependencies
├── README.md              # This file
└── doc.md                 # Detailed documentation
```

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test                   # Run tests (when implemented)

# Manual API testing
curl http://localhost:5000
# Expected response: {"message": "API Running"}
```

### Flutter Testing
```bash
cd simple_mart
flutter test              # Run unit tests
flutter build web         # Test web build
flutter build apk         # Test Android build (requires Android SDK)
```

## 🐛 Troubleshooting

### Common Issues

**Backend won't start:**
- ✅ Check if MySQL is running
- ✅ Verify database credentials in `.env`
- ✅ Ensure port 5000 is not already in use

**Flutter build fails:**
- ✅ Run `flutter doctor` to check installation
- ✅ Run `flutter clean && flutter pub get`
- ✅ Check Flutter SDK version compatibility

**Database connection errors:**
- ✅ Verify MySQL service is running
- ✅ Check firewall settings
- ✅ Confirm database user permissions

### Error Messages

**"ECONNREFUSED" or "Connection refused":**
```bash
# Check if MySQL is running
# Windows:
net start mysql80
# macOS:
brew services start mysql
# Linux:
sudo systemctl start mysql
```

**"Package not found" errors:**
```bash
# Backend
cd backend && npm install

# Flutter
cd simple_mart && flutter pub get
```

## 🔧 Available Scripts

### Backend Scripts
```bash
npm start          # Start production server
npm run dev        # Start development server with auto-restart
npm test           # Run tests (when implemented)
npm run lint       # Code linting (when configured)
```

### Flutter Commands
```bash
flutter run        # Run app in debug mode
flutter build web  # Build for web
flutter build apk  # Build Android APK
flutter test       # Run tests
flutter doctor     # Check Flutter installation
flutter clean      # Clean build cache
```

## 📚 API Endpoints

### Current Endpoints
- `GET /` - API status check
- `GET /health` - Health check endpoint

### Planned Endpoints (Phase 2)
- `POST /api/auth/login` - User authentication
- `GET /api/products` - Get all products
- `POST /api/products` - Create new product
- `GET /api/orders` - Get user orders
- `POST /api/orders` - Create new order

## 🌟 Features

### Current Features (Phase 1)
- ✅ Flutter app foundation
- ✅ Express.js API server
- ✅ MySQL database integration
- ✅ Environment configuration
- ✅ Cross-platform compatibility

### Planned Features (Phase 2+)
- 🔄 User authentication & registration
- 🔄 Product catalog management
- 🔄 Shopping cart functionality
- 🔄 Order management
- 🔄 Payment integration
- 🔄 Admin dashboard

## 📖 Documentation

- **[Detailed Documentation](doc.md)** - Complete project architecture and implementation details
- **[Flutter Documentation](https://flutter.dev/docs)** - Official Flutter guides
- **[Express.js Documentation](https://expressjs.com/)** - Official Express.js guides

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🆘 Support

If you encounter any issues:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review the [Documentation](doc.md)
3. Open an issue on GitHub
4. Contact the development team

## 🎯 Roadmap

- **Phase 1**: ✅ Project Foundation
- **Phase 2**: 🔄 Core Features Development
- **Phase 3**: 🔄 Advanced Features & UI Polish
- **Phase 4**: 🔄 Testing & Deployment

---

Made with ❤️ using Flutter and Express.js
