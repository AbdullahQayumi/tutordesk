# TutorDesk — Google Play Store Metadata & Listing Details

## App Information
- **App Title**: TutorDesk
- **Short Description** (80 chars max):
  All-in-one tutoring management: calendar, student tracking, invoicing & grades.
- **Package Name**: `com.tutordesk.app`
- **Category**: Education / Tools
- **Content Rating**: Everyone

## Full Description (4,000 chars max)

TutorDesk is the complete management platform built specifically for private tutors, tutoring agencies, students, and parents. Simplify your tutoring business and streamline communication—all in one fast, intuitive app.

### Key Features for Tutors & Agencies:
• **Flexible Role Options**: Choose between Solo Tutor (independent tutoring) or Business Mode (team management, staff assignment, and shared schedules).
• **Smart Calendar & Scheduling**: Create recurring or single sessions, track attendance, and detect schedule overlaps automatically.
• **Student & Client Portal**: Keep track of student contact details, session history, notes, and subjects taught.
• **Instant Invoicing & Billing**: Generate polished, printable PDF invoices, record payments, track outstanding balances, and send payment reminders.
• **Integrated Gradebook & Reports**: Record assessment marks, track student progress over time with custom grading scales, and view revenue analytics.
• **Resource Sharing**: Upload and organize lesson documents, PDFs, study guides, and homework materials.

### Dedicated Access for Students & Parents:
• **Student Portal**: Direct login access for students to view lesson schedules, shared study resources, tutor feedback, and progress updates.
• **Parent Portal**: Instant access via secure 5-character access code to monitor attendance, view billing statements, and check child progress.

Whether you're an independent tutor managing a few weekly students or a growing tutoring business with multiple staff members, TutorDesk provides the tools you need to run your tutoring operations effortlessly.

---

## Privacy Policy URL & Requirements
- **Privacy Policy URL**: `https://<your-domain>/privacy` (see hosting options below)
- **Local file**: `privacy.html` (created — ready to deploy)
- **Data Safety Summary**:
  - **Data Collected**: User credentials (email address), account settings, student and session records provided by the user.
  - **Data Encryption**: All network traffic is encrypted in transit using standard HTTPS/TLS (Supabase SSL).
  - **Data Sharing**: Data is strictly isolated by workspace (`org_id`) and is never shared with third parties or advertisers.
  - **Account Deletion**: Users can request complete account and data removal directly from the profile settings.

## Graphic Assets & Specs
1. **App Icon**: 512 x 512 px PNG (32-bit color with alpha, max 1024KB).
2. **Feature Graphic**: 1024 x 500 px PNG or JPEG (no alpha).
3. **Phone Screenshots**: Minimum 2, maximum 8 screenshots (Aspect ratio 16:9 or 9:16, min dimension 320px, max 3840px).
   - *Suggested Screenshots*:
     1. Role Selection & Fast Sign-in (`#roleScreen`)
     2. Calendar & Session Management (`#cal`)
     3. Student Roster & Contact Details (`#people`)
     4. Automated Invoices & Payment Tracking (`#invoices`)
     5. Gradebook & Progress Analytics (`#gradebook`)
4. **Release Package**:
   - **File**: `android/app/build/outputs/bundle/release/app-release.aab`
   - **Signed with**: RSA 2048-bit key (`android/app/keystore/tutordesk-release.keystore`)
