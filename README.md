# HealthTech — Team Project

> A full-stack healthcare platform connecting patients with doctors through

> real-time health monitoring, appointment management, and medical records.

## Table of Contents
- Features
- Architecture
- Tech Stack
- Prerequisites
- Getting Started
- API Documentation
- Deployment
- Team
- Security Notes

## Features
- 4-role system: Admin, Doctor, Patient, Regular User
- Real-time health metrics tracking (heart rate, steps, glucose, BP, sleep, etc.)
- Doctor-patient relationship management
- Appointment scheduling and notifications
- Medical records with prescription tracking
- Emergency contacts management
- Health goals and progress tracking
- AI-powered chatbot
- Symptom logging
- Data export (JSON)
- Auto-simulated health data for development

## Architecture

[ASCII diagram:]

┌──────────────────────────────────────────────────┐

│                  Flutter App                      │

│              (Mobile Frontend)                    │

└───────────────────┬──────────────────────────────┘

                    │ HTTP/REST

┌───────────────────┴──────────────────────────────┐

│              Express.js API Server                │

│                    (Port 3001)                     │

│  ┌─────────┐ ┌──────────┐ ┌──────────────────┐  │

│  │  Auth   │ │  Routes  │ │   Middleware      │  │

│  │  Module │ │  (20+)   │ │  (JWT + Role)     │  │

│  └─────────┘ └──────────┘ └──────────────────┘  │

└───────────────────┬──────────────────────────────┘

                    │ Mongoose

┌───────────────────┴──────────────────────────────┐

│                  MongoDB                          │

│            (Docker / Local)                       │

└──────────────────────────────────────────────────┘

## Tech Stack

### Backend
- Runtime: Node.js >= 16
- Framework: Express.js 4.18
- Database: MongoDB 6.0 + Mongoose 7.6
- Auth: JWT (jsonwebtoken 9.x)
- Validation: express-validator 7.x
- Security: Helmet 7.x, bcryptjs 2.4
- Email: Nodemailer 8.x
- Scheduler: node-cron 4.x

### Frontend
- Mobile: Flutter 3.x (Dart)
- Web (legacy): React 18 + Vite 4

### Infrastructure
- Database: Docker Compose (MongoDB 6.0 + Mongo Express)
- Backend Deployment: Railway / Render
- Frontend Deployment: Firebase Hosting

## Prerequisites
- Node.js >= 16
- Docker & Docker Compose (for MongoDB)
- Flutter SDK >= 3.10 (for mobile frontend)
- Git

## Getting Started

### 1. Clone the Repository

### 2. Start MongoDB (Docker)

### 3. Backend Setup (cd backend, npm install, configure .env, npm run dev)

### 4. Frontend Setup (cd frontend/src/auth2_flutter, flutter pub get, flutter run)

## API Documentation

### Base URL: http://localhost:3001/api

### Auth: All protected endpoints require Authorization: Bearer <token>

### Endpoint Overview Table (grouped by category):

#### Auth (/api/auth)
- POST /register, POST /login, GET /me, POST /forgot-password, POST /reset-password

#### Admin (/api/admin) — requires admin role
- POST /login, GET /users, PUT /users/:id/status, GET /patients,
  PUT /patients/:id, DELETE /patients/:id, POST /create-patient,
  GET /pending-doctor-applications, GET /doctor-applications,
  POST /doctor-applications/bulk-action, POST /approve-doctor/:id,
  POST /reject-doctor/:id

#### User Profile (/api/user)
- PUT /password, DELETE /account, GET /full-profile, PUT /profile,
  GET /check-role, GET /basic-info, POST /apply-for-doctor

#### Health Metrics (/api/health-metrics)
- GET /health-metrics, POST /health-metrics

#### Health Goals (/api/goals)
- POST /, GET /, PUT /:id

#### Medical Records (/api/medical-records)
- POST /, GET /, GET /patients/medical-records

#### Appointments (/api/appointments)
- POST /, GET /, PUT /:id, DELETE /:id

#### Relations (/api/doctor-patient-relations, /api/patients/*)
- POST /doctor-patient-relations, GET /patients/all, GET /patients/doctors

#### Other

- POST /api/emergency-contacts, POST /api/symptom-logs,
  GET /api/symptom-logs, GET /api/notifications, GET /api/health

## Deployment

### Local Development
[Step-by-step for running everything locally]

### Backend Deployment (Railway / Render)
1. Connect GitHub repo
2. Set root directory to `backend`
3. Configure environment variables from `.env.example`
4. Deploy

### Frontend Deployment (Firebase Hosting)
1. Build Flutter web: `flutter build web`
2. Deploy to Firebase Hosting

### Database (MongoDB Atlas)
1. Create free tier cluster
2. Configure connection string in backend env vars

## Team
- Backend: Lim Xinthong — APIs and Server
- Frontend: Joseph — UI/UX (Flutter)
- Database: Cha Weisi — Data Storage and Optimization

## Security Notes
See SECURITY.md for known issues and recommendations.

## License
MIT