# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

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
