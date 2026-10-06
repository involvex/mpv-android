---
goal: Improve mpv-android UI, add command line mode, and YouTube search
version: 1.0
date_created: 2026-04-17
owner: lukas
status: Planned
tags: feature, ui, youtube, command-line
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Modernize the mpv-android app with Material Design 3, add command line mode for mpv shell commands, and implement YouTube search functionality.

## 1. Requirements & Constraints

- **REQ-001**: Material Design 3 theming with dynamic colors
- **REQ-002**: Dark/Light mode toggle with system default option
- **REQ-003**: Persist theme preference in SharedPreferences
- **REQ-004**: Command line input UI accessible from player
- **REQ-005**: Execute mpv commands via command line interface
- **REQ-006**: YouTube search with title/thumbnail display
- **REQ-007**: Play audio from YouTube search results
- **CON-001**: Must maintain existing mpv playback functionality
- **CON-002**: YouTube playback must comply with ToS (streaming only)

## 2. Implementation Steps

### Phase 1: Material Design 3 UI Modernization

- GOAL-001: Update app theme to Material Design 3

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Add Material Components dependency to build.gradle | | |
| TASK-002 | Create Material 3 color schemes (light/dark) | | |
| TASK-003 | Update themes.xml with Material 3 styling | | |
| TASK-004 | Add theme toggle in Settings (System/Light/Dark) | | |
| TASK-005 | Implement theme persistence across app restarts | | |
| TASK-006 | Update dialogs and preferences with Material styling | | |

### Phase 2: Command Line Mode

- GOAL-002: Add mpv command line interface

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Create CommandLineDialogFragment UI | | |
| TASK-008 | Implement command input field with autocomplete | | |
| TASK-009 | Connect to MPVLib command execution | | |
| TASK-010 | Add command history (up/down arrows) | | |
| TASK-011 | Show command output/results | | |
| TASK-012 | Add floating action button to access CLI | | |

### Phase 3: YouTube Search

- GOAL-003: Implement YouTube search and playback

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Add YouTube Data API integration | | |
| TASK-014 | Create YouTube search UI (search bar + results list) | | |
| TASK-015 | Display video thumbnail and title | | |
| TASK-016 | Implement YouTube audio extraction (yt-dlp) | | |
| TASK-017 | Add to playlist functionality | | |
| TASK-018 | Background playback support for YouTube streams | | |

## 3. Alternatives

- **ALT-001**: Use pre-built YouTube library (RapidAPI) - Less control, subscription required
- **ALT-002**: In-browser YouTube playback - Clunky UX, less integration

## 4. Dependencies

- Material Components for Android (1.11.0+)
- YouTube Data API v3
- yt-dlp for audio extraction (or ytdl-org/youtube-dl)
- Kotlin Coroutines for async operations
- Coil for image loading

## 5. Files

- `app/build.gradle` - Add dependencies
- `app/src/main/res/values/themes.xml` - Material 3 theme
- `app/src/main/res/values-night/themes.xml` - Dark theme
- `app/src/main/res/layout/` - New UI layouts
- `app/src/main/java/is/xyz/mpv/CommandLineFragment.kt` - CLI UI
- `app/src/main/java/is/xyz/mpv/YouTubeSearchFragment.kt` - YouTube search
- `app/src/main/java/is/xyz/mpv/ThemeManager.kt` - Theme handling
- `app/src/main/java/is/xyz/mpv/YouTubeService.kt` - API integration

## 6. Testing

- **TEST-001**: Theme toggle works and persists
- **TEST-002**: CLI commands execute and return results
- **TEST-003**: YouTube search returns results with thumbnails
- **TEST-004**: YouTube audio plays in background

## 7. Risks & Assumptions

- **RISK-001**: YouTube may block automated playback - use yt-dlp with auth
- **RISK-002**: Large video files may cause memory issues on mobile
- **ASSUMPTION-001**: User has internet connection for YouTube search