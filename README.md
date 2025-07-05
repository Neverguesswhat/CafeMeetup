# Cafe Meetup iOS App

A sophisticated dating app that facilitates real-world meetups through a unique "Chooser vs Chosen" system with comprehensive date planning, attendance verification, and contact management.

## 🎯 App Concept

Cafe Meetup revolutionizes online dating by focusing on actual meetups rather than endless messaging. The app uses a unique two-role system:

- **Choosers**: Browse and select from available profiles
- **Chosen**: Make themselves visible to be selected by Choosers

## ✨ Key Features

### 🔄 Core Dating Flow
1. **Role Selection**: Users choose to be a "Chooser" or "Chosen"
2. **Profile Browsing**: Choosers see up to 3 available profiles at a time
3. **Match Creation**: Choosers select someone, who then accepts or rejects
4. **Date Planning**: Accepted matches proceed to date planning with 3 venue options
5. **Attendance Verification**: 4-digit codes or QR scanning to verify actual meetings
6. **Rating System**: Post-date ratings determine future visibility

### 📱 Main Features

#### Dashboard
- Dynamic status-based interface
- Real-time match notifications
- Date proposal management
- Attendance confirmation system

#### Profile Management
- Photo upload and management
- Location and bio editing
- Privacy settings
- Account management

#### Date Planning
- 3-date proposal system
- Venue selection from curated Portland locations
- Date/time constraints (within 3 days)
- Interactive maps and directions

#### Attendance Verification
- 4-digit confirmation codes
- QR code scanning system
- Real-time attendance tracking
- Meeting verification

#### Black Book
- Contact management from successful dates
- QR code contact sharing
- Manual contact entry
- Notes and contact details

#### Messaging System
- In-app notifications
- Status updates
- Date reminders
- System messages

#### History & Analytics
- Completed dates tracking
- Rating history
- Match statistics
- Dating journey timeline

## 🏗️ Technical Architecture

### Frontend
- **Framework**: SwiftUI
- **Language**: Swift
- **Target**: iOS 15.0+
- **Architecture**: MVVM with async/await

### Backend
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (profile photos)
- **Real-time**: Supabase Realtime (future enhancement)

### Key Dependencies
- Supabase Swift SDK
- PhotosUI (image picker)
- MapKit (location services)
- Core Image (QR code generation)

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    status TEXT DEFAULT 'default',
    photo_url TEXT,
    location TEXT,
    bio TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    last_active_at TIMESTAMP DEFAULT NOW()
);
```

### Matches Table
```sql
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chooser_id UUID REFERENCES users(id),
    chosen_id UUID REFERENCES users(id),
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Date Proposals Table
```sql
CREATE TABLE date_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES matches(id),
    proposer_id UUID REFERENCES users(id),
    date1 JSONB NOT NULL,
    date2 JSONB NOT NULL,
    date3 JSONB NOT NULL,
    selected_date_index INTEGER,
    status TEXT DEFAULT 'proposed',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Attendance Table
```sql
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_id UUID REFERENCES date_proposals(id),
    user_id UUID REFERENCES users(id),
    confirmed BOOLEAN DEFAULT FALSE,
    confirmation_code TEXT,
    confirmed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Ratings Table
```sql
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_id UUID REFERENCES date_proposals(id),
    rater_id UUID REFERENCES users(id),
    rated_id UUID REFERENCES users(id),
    would_meet_again BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Black Book Table
```sql
CREATE TABLE black_book (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    contact_id TEXT NOT NULL,
    contact_name TEXT NOT NULL,
    contact_email TEXT,
    contact_phone TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Rejection Counts Table
```sql
CREATE TABLE rejection_counts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    count INTEGER DEFAULT 0,
    last_reset_date TIMESTAMP DEFAULT NOW()
);
```

## 🚀 Setup Instructions

### Prerequisites
- Xcode 14.0+
- iOS 15.0+ device or simulator
- Supabase account

### 1. Clone the Repository
```bash
git clone <repository-url>
cd CafeMeetup
```

### 2. Supabase Setup
1. Create a new Supabase project
2. Set up the database tables using the schema above
3. Configure authentication settings
4. Set up storage buckets for profile photos
5. Update `SupabaseManager.swift` with your project credentials

### 3. Environment Configuration
Update the Supabase configuration in `SupabaseManager.swift`:
```swift
client = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

### 4. Build and Run
1. Open `CafeMeetup.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## 🎮 User Flow Example

### Scenario: Dale and Denice

1. **Initial Setup**
   - Dale (Beaverton) and Denice (Gresham) both sign up
   - Both start with "default" status

2. **Role Selection**
   - Denice selects "Be Chosen"
   - Dale selects "Be a Chooser"

3. **Matching Process**
   - Dale sees 3 profiles, including Denice
   - Dale selects Denice
   - Denice receives notification and accepts

4. **Date Planning**
   - Dale proposes 3 dates (Kennedy School, Zach's Shack, Powell's Books)
   - Denice selects one option
   - Dale confirms the date

5. **Attendance Verification**
   - Both confirm they'll attend
   - Denice gets a 4-digit code
   - Dale enters the code to verify they met

6. **Post-Date**
   - Both rate the experience
   - If positive, they can see each other again
   - If negative, they won't appear in each other's choices

## 🔧 Configuration

### Venue Options
The app includes curated Portland-area venues:
- Kennedy School Hot Tub
- Zach's Shack
- Powell's Books
- McMenamins Edgefield
- The Grotto
- Forest Park
- Portland Japanese Garden
- Oaks Amusement Park
- Crystal Springs Rhododendron Garden
- Portland Art Museum

### Location Options
Pre-configured Portland metro areas:
- Beaverton, OR
- Gresham, OR
- Portland, OR
- Lake Oswego, OR
- Tigard, OR
- Hillsboro, OR
- West Linn, OR
- Tualatin, OR
- Wilsonville, OR
- Happy Valley, OR

## 🛡️ Privacy & Security

- User data is encrypted in transit and at rest
- Profile photos are stored securely in Supabase Storage
- Authentication uses Supabase's secure auth system
- Location data is optional and user-controlled
- Rejection limits prevent harassment (3 rejections per 24 hours)

## 🔮 Future Enhancements

- Real-time messaging
- Push notifications
- Advanced matching algorithms
- Video calling integration
- Event-based meetups
- Social media integration
- Premium features
- Analytics dashboard

## 📱 Screenshots

*Screenshots would be added here showing the main app interface*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, email support@cafemeetup.com or create an issue in the repository.

---

**Cafe Meetup** - Making real connections through real meetups. 🎯 