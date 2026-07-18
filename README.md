# RavenVote

Secure, Transparent, and Live E-Voting System for UENR.

## Getting Started

This project is a Flutter application configured with Supabase as the backend.

### Setup

1.  **Supabase:** Follow the [SUPABASE_SETUP.md](SUPABASE_SETUP.md) guide to initialize your database.
2.  **Environment Variables:** Create a `.env` file in the root directory and add your Supabase credentials.
3.  **Run:** Execute `flutter run` to start the application.

## Features

- **Voter Verification:** Multi-factor authentication using Index Number and OTP.
- **Real-time Results:** Live dashboard for monitoring election progress.
- **Admin Command Center:** Management of voters, candidates, and election settings.
- **Offline Support:** Local caching and synchronization for unreliable network conditions.
