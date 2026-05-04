# README.md

# 🏀 Sports Hub - Athlete Management & Analytics System

A comprehensive thesis-level web application for sports teams, coaches, and medical staff to manage athlete data, track performance, and maintain medical records.

## ✨ Features

### Core Modules
- **👥 Player Management** - Create and manage comprehensive player profiles
- **📊 Performance Analytics** - Track games, points, assists, and performance trends
- **⚕️ Medical Records** - Injury history, medical notes, clearance management
- **📋 Training Attendance** - Create sessions and track attendance
- **📅 Event Scheduling** - Manage games, training, and team events
- **🔐 Role-Based Access** - Admin, Coach, Medical Staff, and Player roles with RLS

### Technical Highlights
- **Database**: PostgreSQL via Supabase with 11 optimized tables
- **Authentication**: Email/Password with Supabase Auth + RLS Policies
- **Security**: Row-Level Security enforces access at database level
- **Audit Logging**: Complete audit trail of all data changes
- **Real-Time**: Supabase real-time subscriptions ready
- **Mobile-Responsive**: Fully responsive Tailwind CSS UI

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ (for local development)
- Supabase account (free tier available)
- Netlify account (free tier available)

### 1. Setup Supabase
```bash
# Create free project at https://supabase.com
# Note: Project URL and anon key
```

### 2. Initialize Database
1. Go to Supabase Dashboard → SQL Editor
2. Run entire `docs/DATABASE_SCHEMA.sql`
3. Run entire `docs/RLS_POLICIES.sql`
4. Create Storage bucket: `medical-documents`

### 3. Clone & Configure
```bash
git clone https://github.com/your-username/sports-hub.git
cd sports-hub
npm install

# Create .env file
cp .env.example .env

# Add your Supabase credentials
# VITE_SUPABASE_URL=https://your-project.supabase.co
# VITE_SUPABASE_ANON_KEY=your-key-here
```

### 4. Run Locally
```bash
npm run dev
# Opens http://localhost:3000
```

### 5. Deploy to Netlify
```bash
# Connect GitHub repo to Netlify
# Set environment variables in Netlify UI
# Deploy!
```

## 📁 Project Structure

```
sports-hub/
├── docs/
│   ├── DATABASE_SCHEMA.sql       # 11 tables with relationships
│   ├── RLS_POLICIES.sql          # Role-based access control
│   ├── DOCUMENTATION.md          # Complete API docs
│   └── DEPLOYMENT_GUIDE.md       # Step-by-step deployment
├── src/
│   ├── pages/
│   │   ├── login.html            # Auth page
│   │   └── dashboard.html        # Main interface
│   └── js/
│       ├── supabaseClient.js     # Supabase setup
│       ├── auth.js               # Authentication
│       ├── players.js            # Player CRUD
│       ├── medical.js            # Medical records
│       └── training.js           # Training & events
├── index.html                    # Landing page
└── package.json
```

## 🏗️ Database Schema

### Core Tables
- **users** - User profiles with roles
- **teams** - Sports teams and organizations
- **players** - Athlete profiles and details
- **player_stats** - Performance metrics
- **medical_records** - Injury and health data
- **training_sessions** - Coach-created trainings
- **training_attendance** - Attendance logs
- **games** - Match schedules
- **events** - Calendar events
- **audit_logs** - Change audit trail

### Entity Relationships
```
users (4 roles) ──┬─→ teams ──→ players ──┬─→ player_stats
                 │                        │
                 │                        ├─→ medical_records
                 │                        │
                 │                        └─→ training_attendance
                 │
                 └─→ training_sessions
                 └─→ games
                 └─→ events
                 
All changes → audit_logs
```

## 🔐 Security Features

### Row-Level Security (RLS)
Every table has RLS enabled with policies enforcing:
- **Admins**: Full access to all data
- **Coaches**: Access to their team's players and training
- **Medical Staff**: Access to medical records only
- **Players**: Read-only access to own data

### Audit Trail
Every CREATE, UPDATE, DELETE is logged with:
- User who made change
- Old and new values
- Timestamp
- Table and record ID

## 📚 API Reference

### Authentication
```javascript
import { authManager } from './js/auth.js';

// Register
await authManager.register(email, password, fullName, role);

// Login
await authManager.login(email, password);

// Logout
await authManager.logout();

// Get current user
const user = authManager.getUser();
```

### Players
```javascript
import { getTeamPlayers, createPlayer, updatePlayerStats } from './js/players.js';

const players = await getTeamPlayers(teamId);
const newPlayer = await createPlayer(teamId, playerData);
await updatePlayerStats(playerId, { points_scored: 100 });
```

### Medical Records
```javascript
import { getPlayerMedicalRecords, uploadMedicalDocument } from './js/medical.js';

const records = await getPlayerMedicalRecords(playerId);
const doc = await uploadMedicalDocument(recordId, file, fileName);
```

### Training & Events
```javascript
import { getTeamTrainingSessions, updateAttendance, getTeamEvents } from './js/training.js';

const sessions = await getTeamTrainingSessions(teamId);
await updateAttendance(sessionId, playerId, 'present');
const events = await getTeamEvents(teamId);
```

**See `docs/DOCUMENTATION.md` for complete API reference**

## 🎨 Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | HTML5, JavaScript ES6+, Tailwind CSS |
| Backend | Supabase (PostgreSQL) |
| Authentication | Supabase Auth + RLS |
| Storage | Supabase Storage (files) |
| Hosting | Netlify |
| Build Tool | Vite |

## 📊 Sample Use Cases

### Coach Workflow
1. Create team and add players
2. Create training session
3. Mark attendance
4. View player performance stats
5. Schedule upcoming games

### Medical Staff Workflow
1. Record player injury
2. Upload medical documents
3. Update recovery status
4. Clear player to play
5. View team injury report

### Player Workflow
1. View own profile
2. Check medical clearance
3. See upcoming training sessions
4. View performance stats
5. Check attendance history

## 📈 Performance Analytics

**Built-in Views:**
- `player_performance_summary` - Player stats with injury status
- `training_attendance_summary` - Session attendance rates

**Example Queries:**
```sql
-- Top performers
SELECT first_name, last_name, avg_points_per_game
FROM player_performance_summary
ORDER BY avg_points_per_game DESC;

-- Attendance rates
SELECT team_name, attendance_rate
FROM training_attendance_summary
WHERE session_date > CURRENT_DATE - INTERVAL '30 days';
```

## 🔧 Development

### Add New Feature

1. **Define Database Schema**
   - Update `DATABASE_SCHEMA.sql`
   - Add RLS policies to `RLS_POLICIES.sql`

2. **Create API Module**
   - Add CRUD functions to `src/js/`

3. **Build UI**
   - Create page in `src/pages/`
   - Add navigation link

4. **Test**
   - Verify RLS enforcement
   - Check audit logging
   - Test each role

### Common Tasks
```javascript
// Export to CSV
function exportCSV(data, filename) { /* ... */ }

// Pagination
const { data, count } = await supabase
  .from('players')
  .select('*', { count: 'exact' })
  .range(0, 9);

// Real-time subscriptions
supabase
  .from('player_stats')
  .on('*', payload => console.log(payload))
  .subscribe();
```

## 📋 Thesis Justification

Sports Hub demonstrates:
- ✅ Full-stack architecture (frontend, backend, database)
- ✅ Relational database design with integrity
- ✅ Authentication & authorization patterns
- ✅ Role-based access control via RLS
- ✅ Real-time data management
- ✅ Responsive UI design
- ✅ Security best practices
- ✅ Audit logging & compliance
- ✅ Cloud deployment (Supabase + Netlify)

## 🚀 Scalability Tips

- **Caching**: Redis for frequently accessed data
- **Microservices**: Split into auth, medical, analytics
- **Analytics Engine**: Data warehouse integration
- **Mobile App**: React Native sharing backend
- **Notifications**: Real-time alerts for injuries
- **Video**: Training video storage integration
- **Search**: Elasticsearch for full-text search

## 📖 Documentation

- [Complete API Reference](docs/DOCUMENTATION.md)
- [Database Schema](docs/DATABASE_SCHEMA.sql)
- [RLS Policies](docs/RLS_POLICIES.sql)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)

## 🤝 Support

- **Supabase Docs**: https://supabase.com/docs
- **Tailwind CSS**: https://tailwindcss.com
- **Netlify Support**: https://support.netlify.com

## 📄 License

This project is for academic/thesis purposes.

## 👤 Author

Created as a thesis project demonstrating full-stack web development.

---

**Version**: 1.0.0
**Last Updated**: January 2026

**Deploy Now**: [![Deploy to Netlify](https://www.netlifycdn.com/img/deploy/button.svg)](https://app.netlify.com/start)
