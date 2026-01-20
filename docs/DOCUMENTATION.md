# Sports Hub - Complete Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [System Architecture](#system-architecture)
3. [Database Design](#database-design)
4. [API Reference](#api-reference)
5. [Deployment Guide](#deployment-guide)
6. [Security & RLS](#security--rls)
7. [Development Guide](#development-guide)

---

## Project Overview

**Sports Hub** is a thesis-level web application designed for sports teams, coaches, and medical staff to manage athlete data efficiently.

### Core Objectives
- ✅ Track player profiles and statistics
- ✅ Manage medical records and injury history
- ✅ Monitor training attendance
- ✅ Schedule games and events
- ✅ Implement role-based access control
- ✅ Provide performance analytics

### Target Users
- **Admins**: Full system access, user management
- **Coaches**: Player & team management, training scheduling
- **Medical Staff**: Injury tracking, medical records
- **Players**: View own profiles and medical records (read-only)

---

## System Architecture

### Tech Stack
```
Frontend:     HTML5, JavaScript (ES6+), Tailwind CSS
Backend:      Supabase (PostgreSQL)
Authentication: Supabase Auth + RLS
Storage:      Supabase Storage (medical documents)
Hosting:      Netlify
```

### High-Level Architecture
```
┌─────────────────────────────────────────┐
│          User Interface (Netlify)        │
│    HTML + JavaScript + Tailwind CSS      │
└─────────────────┬───────────────────────┘
                  │
         ┌────────▼────────┐
         │  Supabase Client │
         │   (@supabase/js) │
         └────────┬────────┘
                  │
     ┌────────────┼────────────┐
     │            │            │
┌────▼────┐ ┌────▼────┐ ┌────▼─────┐
│   Auth  │ │   DB    │ │ Storage  │
│ (RLS)   │ │(PG-SQL) │ │ (Files)  │
└─────────┘ └─────────┘ └──────────┘
```

---

## Database Design

### Core Tables

#### 1. **users** - User profiles with roles
```sql
- id (UUID, PK)
- email (TEXT, UNIQUE)
- full_name (TEXT)
- role (TEXT: admin | coach | medical_staff | player)
- team_id (FK: teams.id)
- created_at, updated_at (TIMESTAMPS)
```

#### 2. **teams** - Sports teams
```sql
- id (UUID, PK)
- name (TEXT, UNIQUE)
- sport (TEXT)
- coach_id (FK: users.id)
- created_at, updated_at (TIMESTAMPS)
```

#### 3. **players** - Athlete profiles
```sql
- id (UUID, PK)
- user_id (FK: users.id, UNIQUE)
- team_id (FK: teams.id)
- first_name, last_name (TEXT)
- age (INT)
- position (TEXT)
- jersey_number (INT)
- height_cm, weight_kg (DECIMAL)
- created_at, updated_at (TIMESTAMPS)
```

#### 4. **player_stats** - Performance metrics
```sql
- id (UUID, PK)
- player_id (FK: players.id)
- games_played, points_scored, assists (INT)
- fouls_committed, injuries_count (INT)
- avg_performance_rating (DECIMAL 0-5)
- updated_at (TIMESTAMP)
```

#### 5. **medical_records** - Injury & health data
```sql
- id (UUID, PK)
- player_id (FK: players.id)
- recorded_by (FK: users.id)
- injury_type, injury_date (TEXT, DATE)
- description (TEXT)
- recovery_status (recovering | cleared | cleared_with_restrictions)
- clearance_to_play (BOOLEAN)
- created_at, updated_at (TIMESTAMPS)
```

#### 6. **medical_documents** - File uploads
```sql
- id (UUID, PK)
- medical_record_id (FK: medical_records.id)
- file_path, file_name, file_type (TEXT)
- uploaded_at (TIMESTAMP)
```

#### 7. **training_sessions** - Coach-created sessions
```sql
- id (UUID, PK)
- team_id (FK: teams.id)
- created_by (FK: users.id)
- session_date, session_time (DATE, TIME)
- location, topic, notes (TEXT)
- created_at, updated_at (TIMESTAMPS)
```

#### 8. **training_attendance** - Attendance records
```sql
- id (UUID, PK)
- training_session_id (FK: training_sessions.id)
- player_id (FK: players.id)
- attendance_status (present | absent | excused)
- notes (TEXT)
- recorded_at (TIMESTAMP)
```

#### 9. **games** - Match schedules
```sql
- id (UUID, PK)
- team_id (FK: teams.id)
- opponent_name (TEXT)
- game_date, game_time (DATE, TIME)
- location (TEXT)
- status (upcoming | completed | cancelled)
- notes (TEXT)
- created_at, updated_at (TIMESTAMPS)
```

#### 10. **events** - General calendar events
```sql
- id (UUID, PK)
- team_id (FK: teams.id)
- created_by (FK: users.id)
- event_title, event_description (TEXT)
- event_date, event_time (DATE, TIME)
- event_type (training | game | meeting | medical_checkup)
- location (TEXT)
- status (upcoming | completed | cancelled)
- created_at, updated_at (TIMESTAMPS)
```

#### 11. **audit_logs** - Audit trail
```sql
- id (UUID, PK)
- user_id (FK: users.id)
- action (create | update | delete)
- table_name, record_id (TEXT, UUID)
- old_values, new_values (JSONB)
- created_at (TIMESTAMP)
```

### Relationships Diagram
```
users ────┬────────── teams
          │            ▲
          │            │
          │ (coach_id)
          │
      ┌───┴─────┐
      │          │
   players    medical_staff
      │
      ├─── player_stats
      ├─── medical_records
      ├─── training_attendance
      │       │
      │       └─── training_sessions
      │
      └─── games
          events
```

---

## API Reference

### Authentication Module (`src/js/auth.js`)

```javascript
// Register new user
await authManager.register(email, password, fullName, role, teamId);

// Login
await authManager.login(email, password);

// Logout
await authManager.logout();

// Get current user
const user = authManager.getUser();

// Get current profile
const profile = authManager.getProfile();

// Check role
authManager.hasRole('coach');
authManager.hasAnyRole(['admin', 'coach']);

// Subscribe to auth changes
const unsubscribe = authManager.subscribe((user, profile) => {
  console.log('Auth changed', user, profile);
});
```

### Players Module (`src/js/players.js`)

```javascript
// Get all team players
const players = await getTeamPlayers(teamId);

// Get single player with full details
const player = await getPlayerProfile(playerId);

// Create player
const newPlayer = await createPlayer(teamId, {
  first_name: 'John',
  last_name: 'Doe',
  age: 25,
  position: 'Forward',
  jersey_number: 23,
  height_cm: 180,
  weight_kg: 85
});

// Update player
const updated = await updatePlayer(playerId, { age: 26 });

// Delete player
await deletePlayer(playerId);

// Get player stats
const stats = await getPlayerStats(playerId);

// Update player stats
await updatePlayerStats(playerId, {
  games_played: 10,
  points_scored: 150,
  assists: 25
});
```

### Medical Module (`src/js/medical.js`)

```javascript
// Get player medical records
const records = await getPlayerMedicalRecords(playerId);

// Get single record
const record = await getMedicalRecord(recordId);

// Create medical record
const newRecord = await createMedicalRecord(playerId, {
  injury_type: 'Sprain',
  injury_date: '2026-01-15',
  description: 'Ankle sprain',
  recovery_status: 'recovering',
  clearance_to_play: false
}, userId);

// Update medical record
await updateMedicalRecord(recordId, {
  recovery_status: 'cleared',
  clearance_to_play: true
});

// Upload document
const doc = await uploadMedicalDocument(recordId, file, 'X-ray.pdf');

// Get document URL
const url = await getMedicalDocumentUrl(filePath);

// Get injury statistics
const stats = await getPlayerInjuryStats(playerId);
// Returns: { total_injuries, active_injuries, injury_types, records }

// Get team injury report
const report = await getTeamInjuryReport(teamId);
```

### Training Module (`src/js/training.js`)

```javascript
// TRAINING SESSIONS
const sessions = await getTeamTrainingSessions(teamId);
const session = await getTrainingSession(sessionId);
const newSession = await createTrainingSession(teamId, {
  session_date: '2026-01-20',
  session_time: '15:00',
  location: 'Gym A',
  topic: 'Defensive drills'
}, userId);

// ATTENDANCE
await updateAttendance(sessionId, playerId, 'present', 'On time');
const summary = await getSessionAttendanceSummary(sessionId);
const history = await getPlayerAttendanceHistory(playerId, 3); // Last 3 months
// Returns: { history, stats: { total, present, absent, excused, attendance_rate } }

// GAMES
const games = await getTeamGames(teamId, 'upcoming');
const newGame = await createGame(teamId, {
  opponent_name: 'Team B',
  game_date: '2026-01-25',
  game_time: '19:00',
  location: 'Stadium',
  status: 'upcoming'
}, userId);

// EVENTS
const events = await getTeamEvents(teamId, startDate, endDate);
const newEvent = await createEvent(teamId, {
  event_title: 'Team Meeting',
  event_date: '2026-01-22',
  event_time: '18:00',
  event_type: 'meeting',
  location: 'Conference Room'
}, userId);
```

---

## Deployment Guide

### Prerequisites
- Supabase account (free tier available)
- Netlify account (free tier available)
- Git repository (GitHub, GitLab, or Bitbucket)

### Step 1: Set Up Supabase

1. Create new Supabase project at [supabase.com](https://supabase.com)
2. Run SQL scripts from `docs/DATABASE_SCHEMA.sql`
3. Run RLS policies from `docs/RLS_POLICIES.sql`
4. Copy `Project URL` and `Anon Key` from Settings → API

### Step 2: Configure Environment

Create `.env` file:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### Step 3: Deploy to Netlify

**Option A: Using Netlify UI**
1. Push code to GitHub
2. Connect repository to Netlify
3. Set environment variables in Netlify Dashboard
4. Deploy

**Option B: Using Netlify CLI**
```bash
npm install -g netlify-cli
netlify login
netlify init
netlify deploy
```

### Step 4: Set Up Supabase Storage Buckets

In Supabase Dashboard → Storage:
1. Create bucket: `medical-documents`
2. Set policies to allow authenticated uploads
3. Enable public access for signed URLs

### Post-Deployment
1. Test login at `your-domain.netlify.app/src/pages/login.html`
2. Create test users for each role
3. Verify database operations

---

## Security & RLS

### Security Principles

1. **Row Level Security (RLS)** enforces access at database level
2. **Role-Based Access Control (RBAC)** via user roles
3. **Automatic Audit Logging** tracks all data changes
4. **Data Isolation** - users see only their team's data

### Key RLS Policies

| Table | Admin | Coach | Medical | Player |
|-------|-------|-------|---------|--------|
| users | All | Own | Own | Own |
| players | All | Team's | Team's | Own |
| medical_records | All | - | Team's + Own | Own |
| training_sessions | All | Create/Update own | View | View |
| games | All | Create/Update own | - | View |
| audit_logs | All | - | - | - |

### Implementing Custom Policies

```sql
-- Example: Coach can only update their own team's players
CREATE POLICY "Coaches update own team players" ON players
FOR UPDATE USING (
  auth.uid() IN (
    SELECT id FROM users 
    WHERE role = 'coach' AND team_id = players.team_id
  )
);
```

---

## Development Guide

### Project Structure
```
sports-hub/
├── index.html                 # Landing page
├── public/                    # Static assets
├── src/
│   ├── pages/
│   │   ├── login.html        # Auth page
│   │   ├── dashboard.html    # Main dashboard
│   │   ├── players.html      # Player management
│   │   ├── medical.html      # Medical records
│   │   ├── training.html     # Training & attendance
│   │   └── schedule.html     # Calendar & events
│   ├── js/
│   │   ├── supabaseClient.js # Supabase setup
│   │   ├── auth.js           # Auth logic
│   │   ├── players.js        # Player CRUD
│   │   ├── medical.js        # Medical CRUD
│   │   └── training.js       # Training/Events CRUD
│   └── components/           # Reusable UI components
├── docs/
│   ├── DATABASE_SCHEMA.sql
│   ├── RLS_POLICIES.sql
│   └── DOCUMENTATION.md
├── .env.example
├── package.json
├── tailwind.config.js
├── postcss.config.js
└── vite.config.js
```

### Key Design Patterns

#### 1. Error Handling
```javascript
try {
  const data = await getTeamPlayers(teamId);
} catch (error) {
  console.error('Failed to load players:', error);
  showErrorMessage(error.message);
}
```

#### 2. Loading States
```javascript
showLoading(true);
const data = await fetchData();
showLoading(false);
updateUI(data);
```

#### 3. Authorization Checks
```javascript
if (!authManager.hasAnyRole(['admin', 'coach'])) {
  redirectToAccessDenied();
}
```

### Common Tasks

#### Add a New Module
1. Create database table with appropriate fields
2. Add RLS policies in `docs/RLS_POLICIES.sql`
3. Create CRUD functions in `src/js/module-name.js`
4. Create UI page in `src/pages/`
5. Add navigation link in dashboard

#### Add a New User Role
1. Update `role` CHECK constraint in users table
2. Define RLS policies for new role
3. Update role references in auth and modules
4. Update UI based on role permissions

#### Export Data to CSV
```javascript
function exportToCSV(data, filename) {
  const headers = Object.keys(data[0]);
  const csv = [
    headers.join(','),
    ...data.map(row => 
      headers.map(h => `"${row[h]}"`).join(',')
    )
  ].join('\n');
  
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
}
```

---

## Thesis-Specific Information

### Academic Justification

**Sports Hub** demonstrates:
- Full-stack web application architecture
- Database design with proper relationships and integrity
- Authentication and authorization patterns
- Role-based access control implementation
- Real-time data management with Supabase
- Responsive UI design with Tailwind CSS
- Security best practices (RLS, audit logging)
- RESTful API principles

### Scalability Suggestions

1. **Caching**: Implement Redis for frequently accessed data
2. **Microservices**: Split into separate services (auth, medical, analytics)
3. **Analytics Engine**: Add data warehouse for advanced analytics
4. **Mobile App**: Build React Native app sharing backend
5. **Notifications**: Add real-time notifications for injuries/events
6. **Video Integration**: Store training videos with performance clips
7. **API Rate Limiting**: Implement to prevent abuse
8. **Search Optimization**: Add Elasticsearch for full-text search

---

## Support & Resources

- **Supabase Docs**: https://supabase.com/docs
- **Tailwind CSS**: https://tailwindcss.com/docs
- **JavaScript**: https://developer.mozilla.org/en-US/docs/Web/JavaScript

---

**Last Updated**: January 2026
**Version**: 1.0.0
**Status**: Ready for Thesis Submission
