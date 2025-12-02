# NextStep - Job Platform

A full-stack job application platform built with Flutter (frontend) and Node.js/Express (backend), connecting job seekers with employers.

## Overview

NextStep is a mobile application that allows users to browse job postings, apply for positions, and manage their applications. The platform includes features for both job seekers and employers to post job opportunities and track applications.

## Features

- User registration and authentication
- Job posting creation and management
- Job application system
- User profile management
- Browse available job postings
- View application history
- View posted jobs and applicants

## Technology Stack

### Frontend
- Flutter (Dart)
- Material Design UI
- Shared Preferences for local storage

### Backend
- Node.js
- Express.js
- MySQL/MariaDB (via XAMPP)
- CORS enabled for cross-origin requests

## Project Structure

```
nextstep/
├── lib/
│   ├── constants/          # API configuration
│   ├── models/            # Data models (User, JobPost, Application)
│   ├── pages/             # App screens
│   ├── services/          # API service layer
│   ├── themes/            # App theming
│   └── widgets/            # Reusable widgets
├── Backend/
│   └── NextStep/
│       ├── index.js       # Express server
│       ├── database.sql    # Database schema
│       ├── package.json   # Node.js dependencies
│       └── .env           # Environment variables
└── test/                  # Test files
```

## Prerequisites

Before running this project, ensure you have the following installed:

- Flutter SDK (latest stable version)
- Node.js (v14 or higher)
- XAMPP (for MySQL database)
- Git

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/snavohburmaa/work-platform-nextstep-mobile-programming.git
cd work-platform-nextstep-mobile-programming
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd Backend/NextStep
```

Install dependencies:

```bash
npm install
```

Create a `.env` file in the `Backend/NextStep` directory:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nextstep_db
DB_PORT=3306
DB_SSL=false
PORT=3000
```

### 3. Database Setup

Start XAMPP and ensure MySQL is running.

Import the database schema:

```bash
mysql -u root nextstep_db < database.sql
```

Or use phpMyAdmin:
1. Open phpMyAdmin (http://localhost/phpmyadmin)
2. Create a new database named `nextstep_db`
3. Import `Backend/NextStep/database.sql`

### 4. Start Backend Server

```bash
cd Backend/NextStep
node index.js
```

The server will start on port 3000 (or the port specified in your `.env` file).

### 5. Frontend Setup

Navigate back to the project root:

```bash
cd ../..
```

Install Flutter dependencies:

```bash
flutter pub get
```

Update API configuration if needed. Edit `lib/constants/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

For mobile/emulator testing, use your computer's IP address instead of localhost:

```dart
static const String baseUrl = 'http://192.168.1.XXX:3000';
```

### 6. Run the Application

```bash
npm start
```

## Database Schema

The application uses the following main tables:

- **users**: Stores user account information (recruiters/posters)
- **posts**: Stores job postings
- **applications**: Stores job applications linking users to posts

See `Backend/NextStep/database.sql` for the complete schema.

## API Endpoints

### User Endpoints
- `POST /users` - Register new user
- `POST /users/login` - User login
- `GET /users/:id` - Get user by ID
- `GET /users/email/:email` - Get user by email

### Job Post Endpoints
- `GET /posts` - Get all job posts
- `GET /posts/:id` - Get post by ID
- `GET /posts/user/:userId` - Get posts by user
- `POST /posts` - Create new job post
- `DELETE /posts/:id` - Delete job post

### Application Endpoints
- `POST /apply` - Submit job application
- `GET /applications/user/:userId` - Get applications by user
- `GET /applications/post/:postId` - Get applications for a post
- `GET /applications/check/:postId/:userId` - Check if user applied

## Configuration

### Backend Configuration

Edit `Backend/NextStep/.env` to configure:
- Database connection settings
- Server port
- SSL settings

### Frontend Configuration

Edit `lib/constants/api_config.dart` to configure:
- API base URL
- API endpoints

## Development

### Running in Development Mode

Backend with auto-reload:

```bash
cd Backend/NextStep
npm run dev
```

Frontend hot reload is available by default with `flutter run`.

### Building for Production

Android:

```bash
flutter build apk
```

iOS:

```bash
flutter build ios
```

## Troubleshooting

### Backend Issues

- Ensure MySQL is running in XAMPP
- Check database credentials in `.env`
- Verify port 3000 is not in use
- Check database exists and schema is imported

### Frontend Issues

- Run `flutter pub get` to install dependencies
- Check API base URL matches backend server
- For mobile testing, use IP address instead of localhost
- Check network permissions in Android/iOS configuration

### Database Connection Issues

- Verify XAMPP MySQL is running
- Check database name matches `.env` configuration
- Ensure user has proper permissions
- Check for firewall blocking port 3306




