# ADDA Repository Audit — Version 2.1
**Role:** Senior Staff Flutter Engineer + Product Architect + UI/UX Engineer  
**Date:** September 19, 2026  
**Audited Target:** ADDA Flutter Application (`/Volumes/Crucial_X9/projects/Adda_App`)  
**Baseline Status:** `flutter analyze` clean (0 errors, 0 warnings) | `flutter test` passing (39/39 tests)

---

## 1. Executive Summary

A comprehensive, evidence-based repository audit was conducted across the ADDA codebase. The application is a Flutter/Dart multiplatform project targeting iOS, Android, macOS, Web, Linux, and Windows. 

The audit reveals an extremely high-value core: **12 complete, deterministic, pure-Dart game engines** implementing the unified `ActivityEngine<TState>` contract, backed by full unit test suites. However, the architectural foundation currently suffers from **"Room Coupling Drift"**: games, solo play, and chat are structurally hosted inside an ephemeral or persistent `RoomSession` (`RoomScreen`), and the global navigation retains the legacy `Home | Spaces | Discover | Profile` tab shell.

To satisfy the **ADDA 2.1 Architectural North Star**, ADDA must be migrated from *"a social room app with games attached"* to *"a social gaming platform where PLAY, HANGOUT, CHAT, and SPACES are independent but connected experiences"*.

Working production code (all 12 engines, simulated WebRTC service, signaling protocols, and design tokens) will be **strictly preserved**, while the application shell, solo/bot execution layers, navigation routes, and social/chat domains are migrated incrementally without regressions.

---

## 2. Current Architecture

The application follows a feature-oriented directory structure with clean layered divisions:
```
lib/
├── app/                  # Application bootstrap, router, theme
├── core/                 # Infrastructure services (storage, realtime, webrtc, audio, haptics, logging, errors)
├── features/             # Feature domains
│   ├── activities/       # Core ActivityEngine contracts & PlayerAction models
│   ├── auth/             # Guest identity & user profile domain/data
│   ├── discover/         # Activity browsing & rule discovery
│   ├── games/            # 12 distinct game engines, views, and state models
│   ├── home/             # Home launcher screen & dashboard widgets
│   ├── profile/          # Profile management & local settings
│   ├── room/             # RoomSession, room provider, WebRTC orchestration, chat drawer
│   └── spaces/           # Persistent social spaces domain & data repositories
└── shared/               # Reusable design system tokens & UI components
```

### Architectural Seams & Strengths:
1. **Engine Purity:** Engines in `lib/features/games/*/` have zero dependencies on Flutter UI, WebRTC, or sockets.
2. **State Management:** Riverpod 2.6.1 is used consistently with immutable models and `StateNotifier`.
3. **Simulated Hardware Decoupling:** Audio levels and WebRTC signaling have mock implementations enabling 100% offline, cross-platform local development.

### Architectural Deficits:
1. **Room Hegemony:** `RoomNotifier` controls WebRTC, signaling, chat, participant presence, and active game rendering simultaneously.
2. **Bot Logic in UI Views:** Bot turns in `twenty_nine_view.dart`, `uno_view.dart`, and `bluff_view.dart` are executed via `Future.delayed` and `setState` inside Flutter `StatefulWidget` classes rather than headless domain controllers.
3. **Missing Chat Domain:** Chat is only an ephemeral modal drawer (`RoomChatDrawer`) tied to a room session.

---

## 3. Current Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       └── app_theme.dart
├── core/
│   ├── audio/audio_service.dart
│   ├── errors/failures.dart
│   ├── haptics/haptics_service.dart
│   ├── logging/logger_service.dart
│   ├── realtime/
│   │   ├── realtime_event.dart
│   │   ├── signaling_service.dart
│   │   └── websocket_signaling_client.dart
│   ├── storage/storage_service.dart
│   └── webrtc/webrtc_service.dart
├── features/
│   ├── activities/engine/
│   │   ├── activity_definition.dart
│   │   ├── activity_engine.dart
│   │   └── player_action.dart
│   ├── auth/
│   │   ├── data/auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/user_profile.dart
│   │   │   └── repositories/auth_repository.dart
│   │   └── presentation/providers/auth_provider.dart
│   ├── discover/presentation/screens/discover_screen.dart
│   ├── games/
│   │   ├── bluff/ (bluff_engine.dart, bluff_models.dart, bluff_view.dart)
│   │   ├── brain_arena/ (brain_arena_engine.dart, brain_arena_models.dart, brain_arena_view.dart)
│   │   ├── coop_puzzle/ (coop_puzzle_engine.dart, coop_puzzle_models.dart, coop_puzzle_view.dart)
│   │   ├── couple_mode/ (couple_mode_engine.dart, couple_mode_models.dart, couple_mode_view.dart)
│   │   ├── draw_guess/ (draw_guess_engine.dart, draw_guess_models.dart, draw_guess_view.dart)
│   │   ├── mafia/ (mafia_engine.dart, mafia_models.dart, mafia_view.dart)
│   │   ├── quiz/ (quiz_engine.dart, quiz_models.dart, quiz_view.dart)
│   │   ├── rummy/ (rummy_engine.dart, rummy_models.dart, rummy_view.dart)
│   │   ├── teen_patti/ (teen_patti_engine.dart, teen_patti_models.dart, teen_patti_view.dart)
│   │   ├── twenty_nine/ (twenty_nine_engine.dart, twenty_nine_models.dart, twenty_nine_view.dart)
│   │   ├── uno/ (uno_engine.dart, uno_models.dart, uno_view.dart)
│   │   └── watch_together/ (watch_together_engine.dart, watch_together_models.dart, watch_together_view.dart)
│   ├── home/presentation/screens/home_screen.dart
│   ├── profile/presentation/screens/profile_screen.dart
│   ├── room/
│   │   ├── domain/models/ (chat_message.dart, participant.dart, reaction.dart, room_session.dart)
│   │   └── presentation/
│   │       ├── providers/room_provider.dart
│   │       ├── screens/room_screen.dart
│   │       └── widgets/ (activity_launcher_sheet.dart, compact_game_hud.dart, floating_reaction_overlay.dart, game_mode_sheet.dart, participant_strip.dart, reaction_picker.dart, room_chat_drawer.dart, room_controls_bar.dart)
│   └── spaces/
│       ├── data/space_repository_impl.dart
│       ├── domain/
│       │   ├── models/space_model.dart
│       │   └── repositories/space_repository.dart
│       └── presentation/
│           ├── providers/space_provider.dart
│           ├── screens/spaces_screen.dart
│           └── widgets/ (create_space_sheet.dart, join_space_dialog.dart, space_card.dart)
└── shared/design_system/
    ├── tokens/ (colors.dart, radius.dart, spacing.dart, stickers.dart, typography.dart)
    └── widgets/ (app_avatar.dart, app_button.dart, app_scaffold.dart, app_text_field.dart, speaking_indicator.dart, state_views.dart, surface_card.dart)
```

---

## 4. Current Navigation

The current routing (`lib/app/router.dart`) is built with `go_router: ^17.5.0` using a single `ShellRoute`:
- Bottom Navigation Items:
  1. `/` → `HomeScreen` (Icon: `home_filled`, Label: `'Home'`)
  2. `/spaces` → `SpacesScreen` (Icon: `groups_rounded`, Label: `'Spaces'`)
  3. `/discover` → `DiscoverScreen` (Icon: `explore_rounded`, Label: `'Discover'`)
  4. `/profile` → `ProfileScreen` (Icon: `person_rounded`, Label: `'Profile'`)
- Fullscreen Overlay Route:
  - `/space/:id/room` → `RoomScreen`

### Incompatibilities with ADDA 2.1:
1. Shell tabs do not match the required 4-pillar destinations: `HOME | PLAY | HANGOUT | CHAT`.
2. Dedicated `Profile` tab exists (forbidden by TRD and PRD; must be accessible via top bar avatar pill).
3. Dedicated `Discover` tab exists (its game catalog duties belong in `PLAY`).
4. Uses basic `ShellRoute` instead of `StatefulShellRoute.indexedStack`, which tears down widgets and discards scroll positions and in-progress form inputs when switching tabs.

---

## 5. Current State-Management Architecture

- **Framework:** `flutter_riverpod: ^2.6.1`.
- **Top Providers:**
  - `storageServiceProvider`: Injected at `main.dart` via `ProviderScope(overrides: [...])`.
  - `authProvider`: `AsyncNotifierProvider` managing `UserProfile`. Auto-provisions guest accounts.
  - `spacesProvider`: `AsyncNotifierProvider` querying `SpaceRepository`.
  - `roomProvider`: `StateNotifierProvider` managing `RoomSession?`.
  - `signalingServiceProvider`: Provides `SimulatedSignalingService`.
  - `webrtcServiceProvider`: Provides `DefaultWebRtcService`.
  - `themeModeProvider`: `StateProvider<ThemeMode>` (default `ThemeMode.dark`).
- **State Leakage:**
  - Game states are held as private fields inside `StatefulWidget` classes (`_TwentyNineViewState._state`, `_UnoViewState._state`, etc.) rather than Riverpod `GameSessionNotifier` or `ActivityEngineController`.

---

## 6. Existing Game Engines

All 12 engines implement `ActivityEngine<TState>`:

| Engine | File | Implements Contract | Deterministic | Tests Exist | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Twenty-Nine (29)** | `twenty_nine_engine.dart` | `ActivityEngine<TwentyNineState>` | Yes | `twenty_nine_test.dart` | **PRESERVE** |
| **UNO** | `uno_engine.dart` | `ActivityEngine<UnoState>` | Yes | `uno_test.dart` | **PRESERVE** |
| **Bluff** | `bluff_engine.dart` | `ActivityEngine<BluffState>` | Yes | `bluff_test.dart` | **PRESERVE** |
| **Rummy** | `rummy_engine.dart` | `ActivityEngine<RummyState>` | Yes | `rummy_test.dart` | **PRESERVE** |
| **Teen Patti** | `teen_patti_engine.dart` | `ActivityEngine<TeenPattiState>` | Yes | `teen_patti_test.dart` | **PRESERVE** |
| **Brain Arena** | `brain_arena_engine.dart` | `ActivityEngine<BrainArenaState>` | Yes | `brain_arena_test.dart` | **PRESERVE** |
| **Quiz** | `quiz_engine.dart` | `ActivityEngine<QuizState>` | Yes | `quiz_test.dart` | **PRESERVE** |
| **Draw & Guess** | `draw_guess_engine.dart` | `ActivityEngine<DrawGuessState>` | Yes | `draw_guess_test.dart` | **PRESERVE** |
| **Mafia** | `mafia_engine.dart` | `ActivityEngine<MafiaState>` | Yes | `mafia_test.dart` | **PRESERVE** |
| **Co-op Puzzle** | `coop_puzzle_engine.dart` | `ActivityEngine<CoopPuzzleState>` | Yes | `coop_puzzle_test.dart` | **PRESERVE** |
| **Couple Mode** | `couple_mode_engine.dart` | `ActivityEngine<CoupleModeState>` | Yes | `couple_mode_test.dart` | **PRESERVE** |
| **Watch Together** | `watch_together_engine.dart` | `ActivityEngine<WatchTogetherState>` | Yes | `watch_together_test.dart` | **PRESERVE** |

All engines cleanly serialize/deserialize state to JSON, validate `PlayerAction`, detect completion, and return structured result maps.

---

## 7. Existing Game Implementations / UI

- **Views:** Each game has a dedicated Flutter widget (`TwentyNineView`, `UnoView`, etc.).
- **Rendering Method:** High-contrast custom layouts, cards with border highlights, interactive gesture taps, and `AnimatedSwitcher`.
- **Bot Behavior:**
  - `TwentyNineView`, `UnoView`, and `BluffView` have simulated bot players, but they are implemented as inline methods (`_triggerBotTurnIfNeeded()`) using `Future.delayed(Duration(milliseconds: 600))` inside widget code.
  - Other 9 views currently rely on human interaction or external action dispatch.
- **Flame Status:** Zero Flame code currently in the repository. Flame is planned as a future presentation layer.

---

## 8. Existing Room / Session Architecture

- **Model:** `RoomSession` in `lib/features/room/domain/models/room_session.dart`.
  - Properties: `roomId`, `spaceId`, `spaceName`, `hostId`, `participants`, `chatMessages`, `activeActivityId`, `isConnected`, `isVoiceJoined`, `isSoloMode`.
- **Screen:** `RoomScreen` acts as the host container. It renders either `_buildLoungeView` (participant tiles, quick activity chips, lounge card) or `_buildActiveActivityView` (full-screen game view with `CompactGameHud` and `FloatingReactionOverlay`).
- **Limitation:** A game cannot run without mounting `RoomScreen` or creating a `RoomSession`. This directly contradicts PRD Section 1 & 6.

---

## 9. Existing Chat Architecture

- **Models:** `ChatMessage` (`id`, `senderId`, `senderName`, `content`, `timestamp`, `isSystem`).
- **UI:** `RoomChatDrawer` modal bottom sheet opened from `RoomScreen` controls or `CompactGameHud`.
- **Networking:** Messages broadcast via `RealtimeEvent(type: 'chat.message')`.
- **Deficits:**
  - No standalone `ChatScreen` or `/chat` tab route.
  - No direct messaging (DMs) between friends.
  - No persistent chat threads or conversation history storage.
  - No structured game invitation cards embedded in chat threads.

---

## 10. Existing Voice / Video Architecture

- **Contract:** `WebRtcService` (`state`, `stateStream`, `isMicMuted`, `isCameraEnabled`, `isDeafened`, `localAudioLevelStream`, `initializeMedia()`, `stopMedia()`, `toggleMic()`, etc.).
- **Implementation:** `DefaultWebRtcService` in `lib/core/webrtc/webrtc_service.dart`.
  - Pure Dart simulation of WebRTC session state and VAD (Voice Activity Detection) level emission.
  - No binary native WebRTC dependencies required for compilation or testing.
- **Opt-In Behavior:**
  - Decoupling tests in `room_provider_test.dart` confirm that joining a room does NOT automatically start voice. `isVoiceJoined` defaults to `false`.
  - Solo mode explicitly skips signaling and media connection.

---

## 11. Existing Identity / Auth Architecture

- **Model:** `UserProfile` (`id`, `name`, `isGuest`, `avatarUrl`, `statusMessage`, `createdAt`).
- **Implementation:** `AuthRepositoryImpl` checks `SharedPreferences` for key `adda_current_user_profile`. If absent, it generates a guest identity with a cool nickname (`PixelNomad`, `MidnightRider`, etc.) and persists it.
- **UI:** Full `ProfileScreen` with nickname editor, avatar selector dialog, theme switcher, and sound/haptic toggles.
- **Missing vs ADDA 2.1:**
  - `avatar_seed` parameter not formalized on `UserProfile`.
  - `AddaIdentitySheet` bottom sheet does not exist yet (identity management is stuck on a dedicated bottom tab).

---

## 12. Existing Persistence

- **Service:** `StorageService` (`init()`, `getString()`, `setString()`, `remove()`, `clear()`).
- **Backing:** Wraps `SharedPreferences` with an in-memory fallback map `_memoryFallback` to ensure zero test crashes or uninitialized platform channel issues.
- **Status:** Production-grade, robust, and clean.

---

## 13. Existing Backend / Networking

- **Protocol:** `RealtimeEvent` (event ID, type, roomId, senderId, sequence, payload, timestamp).
- **Client 1:** `SimulatedSignalingService` (in-memory broadcast stream with simulated peer speaking pulses).
- **Client 2:** `WebSocketSignalingClient` (`web_socket_channel` client with heartbeat ping/pong, automatic reconnect backoff, and JSON serialization).
- **Status:** Well-structured and ready for both offline simulation and remote WebSocket gateway connection.

---

## 14. Existing Tests

**39 total tests passing across 14 test suites:**
1. `test/features/games/twenty_nine_test.dart` (4 tests)
2. `test/features/games/uno_test.dart` (3 tests)
3. `test/features/games/bluff_test.dart` (3 tests)
4. `test/features/games/rummy_test.dart` (3 tests)
5. `test/features/games/teen_patti_test.dart` (3 tests)
6. `test/features/games/brain_arena_test.dart` (3 tests)
7. `test/features/games/quiz_test.dart` (3 tests)
8. `test/features/games/draw_guess_test.dart` (3 tests)
9. `test/features/games/mafia_test.dart` (3 tests)
10. `test/features/games/coop_puzzle_test.dart` (3 tests)
11. `test/features/games/couple_mode_test.dart` (3 tests)
12. `test/features/games/watch_together_test.dart` (3 tests)
13. `test/features/spaces/space_repository_test.dart` (4 tests)
14. `test/features/room/room_provider_test.dart` (3 tests)
15. `test/widget_test.dart` (1 app boot smoke test)

---

## 15. Existing Dependencies

### Runtime (`pubspec.yaml`):
- `flutter: sdk: flutter`
- `cupertino_icons: ^1.0.8`
- `flutter_riverpod: ^2.6.1`
- `go_router: ^17.5.0`
- `web_socket_channel: ^3.0.3`
- `uuid: ^4.6.0`
- `shared_preferences: ^2.5.5`
- `google_fonts: ^8.2.1`
- `intl: ^0.20.3`

### Development:
- `flutter_test: sdk: flutter`
- `flutter_lints: ^6.0.0`

No obsolete or conflicting packages. Clean dependency closure.

---

## 16. Existing Design System

- **Tokens:**
  - `AddaColors`: Velvet darks (`bgDark: #090C15`, `surfaceDark: #111625`), radiant accents (`coral: #FF5E5B`, `amber: #FFFFAB00`, `violet: #8C52FF`, `emerald: #00E096`, `cyan: #00E5FF`, `rose: #FFFF3366`).
  - `AddaTypography`: `GoogleFonts.plusJakartaSans` with fallback to `Roboto`.
  - `AddaSpacing`: 4px grid (`xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 24`, `xxl: 32`).
  - `AddaRadius`: `radiusSm: 8`, `radiusMd: 12`, `radiusLg: 16`, `radiusXl: 24`, `radiusFull: 999`.
  - `AddaSticker`: 8 curated expressive sticker models (`stk_chai`, `stk_fire`, `stk_bluff`, etc.).
- **Existing Reusable Widgets:**
  - `AppScaffold`, `SurfaceCard`, `AppButton`, `AppAvatar`, `AppTextField`, `SpeakingIndicator`, `LoadingStateView`, `ErrorStateView`, `EmptyStateView`.
  - `CompactGameHud`, `FloatingReactionOverlay`, `GameModeSheet`.

---

## 17. Existing Assets

- **Assets in pubspec:** None registered.
- **Visuals:** Icons via `MaterialIcons` & `CupertinoIcons`, high-contrast geometric cards, and dynamic sticker/emoji tokens.
- **Audio:** `AudioService` logs SFX triggers (`playCardDeal`, `playCardPlay`, `playReaction`, `playWin`).
- **Haptics:** `HapticsService` wraps native `HapticFeedback` (`lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`).

---

## 18. What Already Matches ADDA v2.1

1. **Deterministic Pure Engines:** All 12 game engines follow `ActivityEngine<TState>`.
2. **Zero-Login First Launch:** Guest user auto-generated with random nickname and saved in `StorageService`.
3. **Simulated Media Abstraction:** `WebRtcService` enables smooth cross-platform execution without native crashes.
4. **Theme & Dark Palette:** Rich velvet dark foundation with vibrant social accents and `Plus Jakarta Sans`.
5. **Opt-In Room Voice:** Room joining does not force audio on; voice connection is explicit.
6. **Tactile Design:** Haptic feedback and sound triggers already instrumented in cards and buttons.

---

## 19. What Conflicts with ADDA v2.1

1. **Navigation Structure:** Current shell has `Home | Spaces | Discover | Profile`. Must be `Home | Play | Hangout | Chat`.
2. **Room as Game Monolith:** Games cannot run without entering a `RoomScreen` or creating a `RoomSession`.
3. **Bot Placement:** Bot turn generation lives inside `StatefulWidget` view files using `Future.delayed` and `setState`.
4. **Dedicated Profile Destination:** Profile occupies a primary bottom tab instead of an avatar sheet.
5. **Discover vs Play:** Discover tab functions as a generic list instead of a game-first arcade.
6. **Chat Isolation:** No independent chat domain or chat tab; chat only exists as an in-room drawer.

---

## 20. What Can Be Preserved

- **ALL 12 Game Engines & State Models:** (`TwentyNineEngine`, `UnoEngine`, `BluffEngine`, `RummyEngine`, `TeenPattiEngine`, `BrainArenaEngine`, `QuizEngine`, `DrawGuessEngine`, `MafiaEngine`, `CoopPuzzleEngine`, `CoupleModeEngine`, `WatchTogetherEngine`).
- **All 39 Existing Unit and Repository Tests.**
- **`StorageService`, `HapticsService`, `AudioService`, `LoggerService`.**
- **`WebRtcService` and `SignalingService` Abstractions.**
- **Design Tokens:** `AddaColors`, `AddaRadius`, `AddaSpacing`, `AddaTypography`, `AddaSticker`.
- **Core Primitives:** `AppButton`, `SurfaceCard`, `AppAvatar`, `SpeakingIndicator`, `CompactGameHud`.
- **Spaces Domain:** `SpaceModel`, `SpaceRepository`, `SpaceRepositoryImpl`, `spacesProvider`.

---

## 21. What Must Be Migrated

- **Router (`lib/app/router.dart`):** Migrate from `ShellRoute` to `StatefulShellRoute.indexedStack` with 4 branches: `/`, `/play`, `/hangout`, `/chat`.
- **Discover Screen:** Migrate into the new `PlayScreen` (Arcade).
- **Profile Screen:** Migrate into `AddaIdentitySheet` modal opened from top app bar avatar pill.
- **Spaces Screen:** Migrate into `HangoutScreen` (supporting Live Now, My Spaces, Create/Join Space).
- **Game UI Views:** Refactor bot logic out of `twenty_nine_view.dart`, `uno_view.dart`, and `bluff_view.dart` into domain-level controllers.

---

## 22. What Is Missing

- **Universal Bot Abstraction (`BotPlayer<TState>`):** Interface and smart heuristic drivers for 29, UNO, and Bluff.
- **Decoupled Game Session Controller (`GameSessionNotifier`):** Independent from `RoomSession`.
- **Play Tab / Arcade Screen (`lib/features/play/presentation/screens/play_screen.dart`):** High-energy arcade hub.
- **Standalone Chat Domain (`lib/features/chat/`):**
  - Thread models (Direct, Space, Game).
  - Repository & local message persistence.
  - Chat hub screen & message conversation view.
  - Structured game challenge / invite cards.
- **Daily Features Domain (`lib/features/daily/`):**
  - Today's Adda prompt of the day.
  - Daily Brain cognitive sprint.
  - Daily streak tracker indicator in top bar.
- **Contextual Top Bar / App Scaffold (`AddaTopBar`):** With avatar identity pill and streak counter.

---

## 23. Technical Risks

1. **Breaking 39 Existing Passing Tests:** Any changes to existing models or repositories must be backward-compatible.
2. **Tab State Destruction:** Switching between games and chat could reset game canvas if standard `ShellRoute` is used instead of `StatefulShellRoute.indexedStack`.
3. **WebRTC Leakage into Gameplay:** Solo play must remain 100% decoupled from WebRTC to avoid unnecessary background battery and audio session locks.
4. **Bot Execution Overlap:** Bot decisions must be serialized and validated against the engine to avoid illegal concurrent actions.

---

## 24. Migration Strategy

We follow a **Safe, Non-Destructive Phased Migration**:
1. **Never delete existing files until their replacements are built, wired, and verified.**
2. **Phase 1 builds the new 4-branch `StatefulShellRoute` shell** while aliasing old routes (`/spaces`, `/discover`, `/profile`) to prevent breaking existing navigation.
3. **Phase 2 formalizes `AddaIdentitySheet` and guest profile extensions** so the top bar avatar cleanly handles identity without needing a bottom tab.
4. **Phase 3 introduces `GameSessionNotifier` and standalone solo play** so games can run directly from `/play/solo/:gameId` without touching `RoomSession`.
5. **Phase 4 extracts `BotPlayer<TState>`** and implements heuristic drivers for flagship games (29, UNO, Bluff).
6. **Subsequent phases construct Chat, Hangout, Daily, and Active Game Dock.**

---

## 25. Recommended Implementation Sequence & Classifications

### Component Classifications

| Component | Current Location | Classification | Action / Target |
| :--- | :--- | :---: | :--- |
| **All 12 Game Engines** | `lib/features/games/*/` | **PRESERVE** | Keep 100% intact, maintain all unit tests. |
| **StorageService** | `lib/core/storage/` | **PRESERVE** | Keep local persistence and memory fallback. |
| **SignalingService** | `lib/core/realtime/` | **PRESERVE** | Keep simulated and WebSocket signaling clients. |
| **WebRtcService** | `lib/core/webrtc/` | **PRESERVE** | Keep simulation and hardware-free state machine. |
| **Design Tokens** | `lib/shared/design_system/tokens/` | **PRESERVE** | Keep colors, radius, spacing, typography, stickers. |
| **Core UI Widgets** | `lib/shared/design_system/widgets/` | **PRESERVE** | Keep AppButton, SurfaceCard, AppAvatar, etc. |
| **App Router** | `lib/app/router.dart` | **MIGRATE** | Replace ShellRoute with 4-tab `StatefulShellRoute.indexedStack`. |
| **Discover Screen** | `lib/features/discover/` | **MIGRATE** | Merge game discovery into `PlayScreen` (Arcade). |
| **Profile Screen** | `lib/features/profile/` | **MIGRATE** | Convert into `AddaIdentitySheet` modal from top app bar. |
| **Spaces Screen** | `lib/features/spaces/` | **MIGRATE** | Integrate as the foundation for `HangoutScreen`. |
| **Room Screen** | `lib/features/room/presentation/` | **REFACTOR** | Decouple game mounting so rooms are purely hangout spaces. |
| **Bot Logic in Game Views** | `twenty_nine_view.dart`, etc. | **REFACTOR** | Extract into `BotPlayer<TState>` and `GameSessionNotifier`. |
| **BotPlayer Abstraction** | — | **MISSING** | Create in `lib/features/activities/engine/bot_player.dart`. |
| **GameSessionNotifier** | — | **MISSING** | Create in `lib/features/games/domain/game_session.dart`. |
| **Play Arcade Screen** | — | **MISSING** | Create `lib/features/play/presentation/screens/play_screen.dart`. |
| **Hangout Screen** | — | **MISSING** | Create `lib/features/hangout/presentation/screens/hangout_screen.dart`. |
| **Chat Domain & Screen** | — | **MISSING** | Create `lib/features/chat/` (models, repository, screen). |
| **Daily Rituals Domain** | — | **MISSING** | Create `lib/features/daily/` (Today's Adda, Daily Brain). |
| **AddaTopBar / Identity Sheet** | — | **MISSING** | Create top bar avatar pill & `AddaIdentitySheet`. |

---

### Implementation Phases
- **Phase 0 (Complete):** Repository Audit & Baseline Verification (`ADDA_REPOSITORY_AUDIT.md`).
- **Phase 1 (Next):** Application Shell & 4-Branch Routing (`Home | Play | Hangout | Chat`) with `StatefulShellRoute.indexedStack`.
- **Phase 2:** Guest Identity & Top Bar `AddaIdentitySheet` (removing Profile bottom tab cleanly).
- **Phase 3:** Independent Game Session Architecture (decoupling games from `RoomSession`).
- **Phase 4:** Universal `BotPlayer<TState>` Subsystem (29, UNO, Bluff heuristic drivers).
- **Phase 5:** PLAY Arcade Hub (game catalog, solo vs bots launcher, table creation).
- **Phase 6:** HANGOUT & Persistent Spaces Surface (Live Now, My Spaces, Create/Join).
- **Phase 7:** Opt-In Media Hardening (explicit voice/video controls, zero media leaks).
- **Phase 8:** CHAT Domain & Hub (Direct, Space, Game threads & interactive invites).
- **Phase 9:** Home Activity Launcher & Daily Rituals (Today's Adda, Daily Brain sprint).
- **Phase 10:** Floating Active Game HUD / Session Dock.
- **Phase 11:** Flame Presentation Bridge.
- **Phase 12:** Production Hardening, accessibility, and offline verification.
