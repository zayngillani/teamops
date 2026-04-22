# Application Testing Workflow (QA Guide)

This document outlines the core functional flows of the TeamOps portal for Quality Assurance testing.

## 1. Authentication & Role Access
- **Test Credentials**:
  - Super Admin: `admin@teamops.com` / `admin123`
  - Developer: `dev@teamops.com` / `password123`
- **Goal**: Verify that Admins can see the "Users" and "Settings" tabs, while standard users cannot.
- **Goal**: Verify "Outside IP Restriction". If enabled for a user, they should only be able to log in from authorized office IPs.

## 2. Attendance Tracker (Core Flow)
- **Step 1: Clock In**
  - Click "Start Working Day".
  - Verify: Timer starts at `00:00:01`. Slack notification is sent. Status changes to "Clocked In".
- **Step 2: Take Break**
  - Click "Take Break".
  - Verify: Main timer pauses/switches to "Break Timer". Break timer starts from `00:00:01`.
- **Step 3: Resume Work**
  - Click "Resume Work".
  - Verify: Clock switches back to "Work Timer" and continues from where it left off.
- **Step 4: Finish Day**
  - Click "Finish Day".
  - Verify: A report modal appears.
  - Action: Enter at least 10 characters and confirm.
  - Verify: User is moved to "Offline" state. Total time is calculated correctly (Total - Breaks).

## 3. Data Integrity & Reporting
- **Daily Reports**: Go to "Reports" tab. Verify your checkout report appears with the correct work/break durations.
- **Attendance History**: Check the history table. Verify "Check In" and "Check Out" times match your local clock.
- **Monthly Summary**: Verify the top cards (Work Hours, Break Time) update correctly after finishing a session.

## 4. User Management (Admin Only)
- **Create User**: Add a new user. Verify they get a "Feature Toggle" record created automatically.
- **Feature Toggles**: 
  - Go to User Edit.
  - Toggle "API Keys" or "GitHub Enabled".
  - Verify: The specific user now sees (or loses access to) those specific dashboard modules.

## 5. Security & Edge Cases
- **Weekend Restriction**: Attempt to Clock In on a Saturday/Sunday. Non-admins should be restricted.
- **Leave Integration**: Create an "Approved" leave for today. Attempt to Clock In. System should deny access.
- **Negative Timers**: Ensure timer never shows negative values even if clock sync varies by a few seconds.
