# Sports Hub - Revamped Athlete Management & Analytics System

## Overview

Sports Hub is a comprehensive athlete management and analytics system designed for sports teams, coaches, and medical staff. This revamped version features **normal CRUD operations without email confirmation**, enhanced **analytics and statistics**, and comprehensive **medical record tracking** to determine player work readiness.

## 🚀 Key Features

### Authentication & User Management
- **No Email Confirmation Required** - Users can register and login immediately
- Role-based access control (Admin, Coach, Medical Staff, Player)
- Secure authentication with Supabase Auth
- Automatic user profile creation

### Player Management & Analytics
- Complete player profiles with physical metrics
- **Real-time availability tracking** based on medical records
- Performance statistics and trends
- **Work readiness assessment** - Know if a player is amenable to work
- Fitness scoring and injury risk assessment

### Medical Records & Availability Tracking
- Comprehensive injury history with severity levels
- Medical assessments and fitness evaluations
- **Automatic availability status updates**
- Recovery tracking with expected return dates
- Medical clearance management
- Document upload and management

### Analytics & Statistics
- **Team performance dashboard** with key metrics
- Player availability overview (Available/Injured/Restricted)
- Injury statistics and trends
- Training attendance analytics
- Fitness metrics and performance trends
- Medical analytics and risk assessment

### Training & Schedule Management
- Training session creation and management
- Attendance tracking with multiple status options
- Event scheduling and calendar integration
- Performance correlation with attendance

## 🏗️ Technical Architecture

### Frontend
- **HTML5** with modern semantic structure
- **JavaScript ES6+** modules for clean code organization
- **Tailwind CSS** for responsive, modern UI
- **Font Awesome** icons for enhanced UX

### Backend & Database
- **Supabase** (PostgreSQL) for robust data management
- **Row Level Security (RLS)** for data protection
- **Real-time subscriptions** for live updates
- **Comprehensive views** for analytics queries

### Key Database Enhancements
- Enhanced medical records with severity tracking
- Player analytics table for availability status
- Team statistics for performance metrics
- Medical assessments for fitness tracking
- Comprehensive audit logging

## 📊 Analytics & Player Availability

### Player Work Readiness Assessment
The system automatically determines if a player is amenable to work based on:

1. **Latest Medical Records**
   - Injury status and recovery progress
   - Medical clearance status
   - Restrictions and limitations

2. **Fitness Assessments**
   - Overall fitness score (0-10)
   - Cardiovascular, strength, and flexibility metrics
   - Injury risk level assessment

3. **Availability Status**
   - Available: Ready for full participation
   - Injured: Cannot participate due to injury
   - Restricted: Limited participation with conditions
   - Suspended: Administrative restrictions

### Analytics Dashboard Features
- **Real-time availability overview** with visual indicators
- **Team fitness metrics** and performance trends
- **Injury statistics** by type, severity, and recovery status
- **Training attendance correlation** with performance
- **Medical risk assessment** for injury prevention

## 🔧 Installation & Setup

### Prerequisites
- Node.js (v16 or higher)
- Supabase account
- Modern web browser

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sportshub
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Run the SQL schema from `docs/DATABASE_SCHEMA.sql`
   - Update Supabase credentials in `src/js/supabaseClient.js`

4. **Disable Email Confirmation**
   In your Supabase dashboard:
   - Go to Authentication > Settings
   - Disable "Enable email confirmations"
   - Set "Site URL" to your domain

5. **Start development server**
   ```bash
   npm run dev
   ```

6. **Access the application**
   - Open `http://localhost:5173` in your browser
   - Register a new account (no email confirmation needed)
   - Start managing your team!

## 📋 Usage Guide

### For Coaches
1. **Register** with coach role
2. **Add players** to your team
3. **Create training sessions** and track attendance
4. **Monitor player availability** and fitness status
5. **View analytics** to make informed decisions

### For Medical Staff
1. **Register** with medical_staff role
2. **Create medical records** for injuries
3. **Conduct fitness assessments**
4. **Update player clearance status**
5. **Monitor team health metrics**

### For Players
1. **Register** with player role
2. **View your profile** and statistics
3. **Check training schedule**
4. **Review medical status** and restrictions

## 🔍 Key API Endpoints

### Player Availability
```javascript
// Check if player is ready to work
const readiness = await checkPlayerWorkReadiness(playerId);
console.log(readiness.canWork); // true/false
console.log(readiness.status); // 'Ready to Play', 'Not Available', etc.
```

### Team Analytics
```javascript
// Get comprehensive team report
const report = await generateTeamReport(teamId);
console.log(report.availability.summary); // Available/injured counts
console.log(report.fitness.avg_overall_fitness); // Team fitness average
```

### Medical Records
```javascript
// Create medical record with availability update
const record = await createMedicalRecord(playerId, {
  injury_type: 'Ankle Sprain',
  severity: 'moderate',
  clearance_to_play: false,
  expected_return_date: '2024-02-15'
}, userId);
```

## 🎯 Core Improvements

### 1. Simplified Authentication
- ✅ No email confirmation required
- ✅ Immediate account activation
- ✅ Streamlined registration process

### 2. Enhanced Medical Tracking
- ✅ Severity levels for injuries
- ✅ Expected vs actual return dates
- ✅ Automatic availability status updates
- ✅ Comprehensive fitness assessments

### 3. Advanced Analytics
- ✅ Real-time availability dashboard
- ✅ Performance trend analysis
- ✅ Injury risk assessment
- ✅ Training correlation metrics

### 4. Work Readiness Assessment
- ✅ Automated status determination
- ✅ Medical clearance tracking
- ✅ Restriction management
- ✅ Return-to-play protocols

## 🔒 Security Features

- **Row Level Security (RLS)** policies for data isolation
- **Role-based access control** for different user types
- **Audit logging** for all data changes
- **Secure file upload** for medical documents
- **Input validation** and sanitization

## 📱 Responsive Design

- **Mobile-first approach** with Tailwind CSS
- **Responsive tables** and charts
- **Touch-friendly interface** for tablets
- **Progressive Web App** capabilities

## 🚀 Deployment

### Netlify (Recommended)
1. Connect your GitHub repository
2. Set build command: `npm run build`
3. Set publish directory: `dist`
4. Deploy automatically on push

### Manual Deployment
1. Build the project: `npm run build`
2. Upload `dist` folder to your web server
3. Configure redirects for SPA routing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the documentation in the `docs/` folder
- Review the database schema in `docs/DATABASE_SCHEMA.sql`
- Check the deployment guide in `docs/DEPLOYMENT_GUIDE.md`

---

**Sports Hub v2.0** - Enhanced athlete management with comprehensive analytics and medical tracking for optimal team performance.