# TeamOps Portal

A modern, high-performance Attendance and Team Management system built with Next.js 14, TypeScript, and Prisma.

## Tech Stack
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Database**: PostgreSQL (Prisma ORM)
- **Styling**: Tailwind CSS + Framer Motion (Glassmorphism UI)
- **Authentication**: NextAuth.js
- **Notifications**: Slack Integration

## Core Features
- **Attendance Tracker**: Single-record-per-day model with active Work/Break dual timers.
- **Role-Based Access**: Specialized roles (Super Admin, Admin, Developer, QA, HR, etc.) with granular feature toggles.
- **Reporting**: Daily work reports and monthly performance summaries.
- **Security**: IP-based access restriction (Outside IP restriction).
- **Slack Integration**: Real-time notifications for Clock-in, Breaks, and Check-outs.

## Setup Instructions
1. **Clone the repo**: `git clone https://github.com/zayngillani/teamops.git`
2. **Install dependencies**: `npm install`
3. **Set up Environment**: Create a `.env` file based on the provided schema.
4. **Database Sync**: `npx prisma db push`
5. **Seed Data**: `npm run seed` (Admin: admin@teamops.com / admin123)
6. **Run Dev Server**: `npm run dev`

## Documentation for QA
Refer to [QA_WORKFLOW.md](./QA_WORKFLOW.md) for detailed testing instructions.
