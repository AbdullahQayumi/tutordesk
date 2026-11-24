# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language Rule

ALWAYS respond strictly in English. Never reply in any other language.

## Current Progress — TutorDesk Mobile App

**Role selection screen (done).** The mobile sign-in flow now starts at a `#roleScreen` (`index.html:568`) with three cards: **Tutor**, **Student**, and **Parent**. Each button in `src/main.js` routes to its own screen — Tutor goes to the existing `#authScreen` (login/signup, supports solo/business), Student goes to `#studentPortalView` (email + SHA-256 password via the `verify_student_login` RPC), and Parent goes to `#parentPortalView` (5-character access code via the `verify_parent_code` RPC). Back buttons on the student/parent login boxes return to the role screen, and logout resets to it. CSS rule `body.authed #roleScreen{display:none}` hides the role screen once a Tutor is authenticated.

**Signed Android release build (done).** `npm run build:app` syncs the Vite bundle into `android/app/src/main/assets/public/`, then `./gradlew bundleRelease` produces a signed AAB at `android/app/build/outputs/bundle/release/app-release.aab` (3.1 MB). The keystore is `android/app/keystore/tutordesk-release.keystore` (2048-bit RSA, 10,000-day validity, CN=Abdullah Qayumi / TutorDesk, SHA384withRSA). Signing config lives in `android/app/build.gradle` and reads `key.properties`.

**Next step — redesign the mobile sign-in/sign-up screen.** The Tutor auth screen (`#authScreen`) is shared between login and signup and is fairly plain. The plan is to give it a cleaner mobile-first redesign, consistent with the new role-card styling, and then rebuild and re-sign the AAB. After that: test on a physical device (none connected right now — the emulator fails with insufficient disk space), then finalize Play Store metadata (privacy policy URL, store listing text, icons, screenshots).

- `npm run dev` - Start Vite local development server
- `npm run build` - Build production web bundle into `dist/`
- `npm run preview` - Preview production build locally
- `npm run build:app` - Build bundle and sync Capacitor native project
- `npm run android` - Build app and open Android Studio project

*Note: No automated test framework or linter is currently configured.*

## Environment Setup

Requires environment variables in `.env`:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

## Architecture & Structure

TutorDesk is a tutoring management app built with Vanilla JS (ES Modules), Vite, Supabase backend, and Capacitor for mobile containerization.

### Core Architecture

- **UI Controller (`src/main.js` & `index.html`)**: Frameworkless single-page app using direct DOM manipulation (`$()` helper). Controls screen navigation (`#home`, `#cal`, `#people`, `#invoices`, `#resources`, `#gradebook`, `#reports`, `#profile`), dialog modals, and calendar layout math (overlapping session calculations).
- **Data Layer & In-Memory Cache (`src/store.js`)**: Loads all workspace data into memory on login via `loadAll()`. All reads are synchronous against in-memory arrays/maps. Writes execute Supabase database operations first and update local memory on success.
- **Authentication & Multi-Tenancy (`src/auth.js`, `src/store.js`)**: Handles Supabase Auth. Data is isolated by workspace (`org_id`). Supports `solo` and `business` workspace types with role-based access (`owner`, `admin`, `staff`).
- **Supabase Client (`src/supabase.js`)**: Exports initialized `@supabase/supabase-js` client instance using Vite environment variables.
- **Mobile Packaging (`capacitor.config.json`)**: Capacitor configuration pointing `webDir` to `dist`.
