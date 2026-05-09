# Cooksy

A best-in-class iOS app that converts social media cooking links (YouTube, TikTok, Instagram) into structured, saveable recipes.

## Tech Stack

- **Language**: Swift 5.10
- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with `@Observable`
- **Persistence**: SwiftData
- **Backend**: Supabase (Auth, PostgreSQL, Edge Functions)
- **Payments**: RevenueCat (In-App Purchases)

## Features

- Recipe import from YouTube, TikTok, and Instagram URLs
- OTP email authentication + Sign In with Apple
- Interactive ingredient checklist
- Immersive step-by-step cooking mode
- Recipe books/collections
- Subscription management
- Full VoiceOver, Dynamic Type, and Dark Mode support

## Project Structure

```
Sources/Cooksy/
├── Core/
│   ├── Models/         # SwiftData @Model types
│   ├── DesignSystem/   # Reusable UI components
│   ├── Services/       # Supabase, RevenueCat, DI
│   └── Utils/          # Formatters, Validators
├── Features/           # 10 feature modules
└── Resources/          # Icons, Info.plist, Privacy Manifest
```

## Getting Started

1. Open `Package.swift` in Xcode
2. Configure your Supabase URL and anon key
3. Configure your RevenueCat API key
4. Build and run on iOS 17+ simulator or device

## Architecture

- **Dependency Injection**: `SupabaseProtocol` with `Environment` injection
- **State Management**: `@Observable` ViewModels with SwiftData persistence
- **Error Handling**: Typed `CooksyError` with user-friendly messages
- **Accessibility**: Full VoiceOver labels, Dynamic Type, Reduce Motion support
