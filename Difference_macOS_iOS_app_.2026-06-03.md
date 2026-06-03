> **Note:** This is Claude Code's own review of the differences. Some of the features it has marked as Status 'Complete' I haven't found in the iOS app. Take this with a big pinch of salt. I'll look into it when I feel like it.

# Claude Usage Tracker — macOS → iOS Gap Analysis
_Generated 2026-06-03_

## Feature Table

| Feature | macOS Implementation | iOS Status | Gap / Notes | Effort |
|---|---|---|---|---|
| **1. Credential Management** | | | | |
| Session key entry (sk-ant-sid01-…) | `CredentialsView`, `SetupWizardView` | ✅ Complete | `CredentialsView` + `ProfileDetailView` fully implemented | — |
| Session key format validation | `SessionKeyValidator` | ✅ Complete | Validator ported to iOS, wired on input | — |
| Keychain storage | `KeychainMigrationService` (profile-stored, legacy) | ✅ Complete | iOS correctly uses iOS Keychain; cleaner than macOS | — |
| Org ID auto-resolved from `/organizations` | `ClaudeAPIService.readOrganizationId()` | ✅ Complete | Both resolve and cache on first use | — |
| Multi-org picker after key test | `CredentialsView` org picker | ✅ Complete | Picker shown after test succeeds | — |
| API Console session key (console.anthropic.com) | `APIBillingView`, `ClaudeAPIService+ConsoleAPI` | ❌ Missing | `APIUsage` model + `consoleBase` URL both ported; no fetch service, no `Profile.apiUsage` field, no UI | M |
| CLI OAuth credentials sync | `ClaudeCodeSyncService`, `CLIAccountView` | 🚫 N/A | Reads `~/.claude/.credentials.json` + macOS Keychain; iOS sandbox blocks Mac file access | — |
| API session key expiry tracking + notification | `Profile.apiSessionKeyExpiry`, scheduled `UNCalendarNotificationTrigger` | ❌ Missing | macOS tracks console API key expiry and fires 24h-before alert; iOS has no expiry concept | S |
| **2. Usage Data** | | | | |
| Session (5h) percentage + reset time | `ClaudeUsage.sessionPercentage/.sessionResetTime` | ✅ Complete | Both parse `five_hour` identically | — |
| Effective session % (returns 0% if window expired) | `ClaudeUsage.effectiveSessionPercentage` | ✅ Complete | Identical logic in `Shared/ClaudeUsage.swift` | — |
| Weekly (7-day all models) % + reset time | `ClaudeUsage.weeklyPercentage` | ✅ Complete | Both parse `seven_day` | — |
| Opus weekly % | `ClaudeUsage.opusWeeklyPercentage` | ✅ Complete | Parsed and displayed in model breakdown card | — |
| Sonnet weekly % + reset time | `ClaudeUsage.sonnetWeeklyPercentage` | ✅ Complete | Parsed; `sonnetWeeklyResetTime` also stored | — |
| Monthly overage spend (`overage_spend_limit`) | `ClaudeUsage.costUsed/costLimit` | ✅ Complete | Both fetch; iOS shows "Monthly Overage" card | — |
| Overage credit grant balance | `ClaudeUsage.overageBalance` | ✅ Complete | Both fetch; iOS shows credit balance row | — |
| API Console billing (spend, prepaid credits, resets) | `APIUsage`, `ClaudeAPIService+ConsoleAPI` | ❌ Missing | `APIUsage` model fully ported; no fetch, no profile field, no UI | M |
| API spend by model breakdown | `APIUsage.apiCostByModel` | ❌ Missing | Blocked on API Console credentials | M |
| API cost by source (CLI vs API key) | `APIUsage.costBySource / APICostSource` | ❌ Missing | Model ported; blocked on credentials | M |
| Daily spend chart | `APIUsage.dailyCostCents` | ❌ Missing | Model ported; blocked on credentials | L |
| **3. Multi-Profile Management** | | | | |
| Profile CRUD | `ProfileManager` | ✅ Complete | Create/update/delete/activate all work | — |
| Active profile switching with auto-refresh | `ProfileManager.activateProfile` | ✅ Complete | iOS switches and refreshes immediately | — |
| Per-profile credentials | `Profile.claudeSessionKey + organizationId` | ✅ Complete | Each profile has isolated key and org ID | — |
| Per-profile cached usage data | `Profile.claudeUsage` | ✅ Complete | Shown in profile list rows | — |
| Per-profile refresh interval | `Profile.refreshInterval` | ✅ Complete | Both store and respect per-profile value | — |
| Per-profile notification settings | `Profile.notificationSettings` | 🟡 Partial | Model + threshold toggles UI present; `AppState.refresh()` never calls any dispatch | S |
| Delete protection (≥1 profile) | `guard profiles.count > 1` | ✅ Complete | Swipe-to-delete disabled on last profile | — |
| Profile auto-switch on session limit | `UsageRefreshCoordinator` | ❌ Missing | macOS auto-switches to next profile when active profile hits 100% | S |
| Multi-profile display mode (single/multi) | `ProfileDisplayMode`, `isSelectedForDisplay` | 🚫 N/A | Menu bar icon concept; iOS uses tab navigation | — |
| CLI account per-profile sync metadata | `Profile.hasCliAccount`, `oauthAccountJSON` | 🚫 N/A | macOS Claude Code integration; no iOS equivalent | — |
| Profile funny-name generator | `FunnyNameGenerator` | ❌ Missing | Auto-generates witty profile names; minor UX touch | S |
| **4. Appearance / Display Settings** | | | | |
| WidgetKit home screen widget (small) | — (macOS has no widget) | ✅ Complete | Circle gauge + weekly bar + reset times | — |
| WidgetKit home screen widget (medium) | — | ✅ Complete | Two-column gauges | — |
| App Group UserDefaults → widget | `AppGroupStore` | ✅ Complete | Writes on each refresh, reloads timelines | — |
| Show remaining % vs used % toggle | `MenuBarIconConfiguration.showRemainingPercentage` | ❌ Missing | iOS always shows used %; `remainingPercentage` computed property exists on model | S |
| Week display: percentage vs token count | `WeekDisplayMode` (.percentage / .tokens) | ❌ Missing | `weeklyTokensUsed` already calculated; just needs a toggle | S |
| Menu bar icon color modes (multi/mono/single) | `MenuBarColorMode` | 🚫 N/A | Menu bar concept; not applicable to iOS | — |
| Per-metric enable/disable/ordering | `MetricIconConfig`, `MenuBarIconConfiguration` | 🚫 N/A | Menu bar icon slots; iOS scrollable view shows everything | — |
| Time marker / pace marker on bar | `showTimeMarker`, `showPaceMarker` | 🚫 N/A | Menu bar visual elements | — |
| **5. Notifications & Threshold Alerts** | | | | |
| Permission request flow | `UNUserNotificationCenter.requestAuthorization` | ✅ Complete | Request, granted, denied state with Settings link | — |
| Enable/disable toggle | `NotificationSettings.enabled` | ✅ Complete | Toggle in `SettingsView` | — |
| 75% / 90% / 95% threshold toggles (UI) | `NotificationSettings.*Enabled` | ✅ Complete | All three toggles visible when notifications enabled | — |
| **Actual notification dispatch** | `NotificationManager.checkAndNotify()` | ❌ Missing | `AppState.refresh()` never calls any check; all UI is wired but nothing fires | M |
| Session reset notification | `AlertType.sessionReset` | ❌ Missing | Requires dispatch to exist first | S |
| Weekly usage warnings (weekly/opus thresholds) | `AlertType.weeklyWarning/.opusWarning` | ❌ Missing | Defined in macOS but only fires when dispatch exists | S |
| Custom thresholds | `NotificationSettings.customThresholds: [Int]` | 🟡 Partial | `[Int]` field exists in model; no UI to add/remove values | S |
| Notification sound selection | `soundName` + `NSSound.play()` | ❌ Missing | macOS uses AppKit `NSSound`; iOS would use `UNNotificationSound` (bundled sounds only) | S |
| Notification deduplication | `sentNotifications: Set<String>` in `UserDefaults` | ❌ Missing | Without this, every refresh re-fires already-sent alerts | S |
| Session key expiry alert (24h scheduled) | `UNCalendarNotificationTrigger` | ❌ Missing | macOS schedules for console API key; iOS has no expiry tracking | S |
| **6. Auto-Start Sessions** | | | | |
| Per-profile auto-start toggle | `Profile.autoStartSessionEnabled` | ❌ Missing | Field absent from iOS `Profile` model | M |
| Background monitoring (5-min cycle) | `AutoStartSessionService` + `Timer` | ❌ Missing | Would require `BGAppRefreshTask` on iOS; heavily OS-throttled | L |
| Create conversation + send "Hi" + delete | `sendInitializationMessage()` | ❌ Missing | API calls exist in `ClaudeAPIService` but not wired for this purpose | L |
| Sleep/wake handling | `NSWorkspace.didWakeNotification` | 🚫 N/A | macOS-specific; iOS equivalent is `UIApplication.didBecomeActiveNotification` | — |
| **7. Network Monitoring & Offline Handling** | | | | |
| `NWPathMonitor` | `NetworkMonitor` | ✅ Complete | Identical implementation | — |
| Auto-refresh on reconnect | `onNetworkAvailable` callback | ✅ Complete | Wired in `AppState.init()` | — |
| Explicit offline banner/indicator | Implied via error state | 🟡 Partial | Shows generic error; no distinct "offline" message or persistent indicator | S |
| **8. Refresh Interval Configuration** | | | | |
| Configurable refresh interval | Slider 10–300s | ✅ Complete | iOS uses preset Picker; macOS uses Slider; both store in `Profile.refreshInterval` | — |
| Auto-restart timer on change | `scheduleRefresh()` | ✅ Complete | Called on profile update | — |
| **9. Language / Localisation** | | | | |
| Localised strings (14 languages) | 14 `.lproj` bundles, `LanguageManager` | ❌ Missing | All iOS strings are hardcoded English; no `.lproj` files | L |
| In-app language picker | `LanguageSettingsView` | 🚫 N/A | iOS follows system language; no override picker needed | — |
| **10. Update Mechanism** | | | | |
| Sparkle auto-update | `UpdateManager` (SPUStandardUpdaterController) | 🚫 N/A | App Store handles iOS distribution | — |
| **11. Claude Code / Statusline Integration** | | | | |
| Statusline bash + Swift scripts | `StatuslineService` | 🚫 N/A | Writes to `~/.claude/`; iOS sandbox prevents this | — |
| Statusline config (model, branch, context, usage, weekly) | `ClaudeCodeView`, `StatuslineService.updateConfiguration()` | 🚫 N/A | macOS terminal UI concept | — |
| `ClaudeCodeSyncService` (OAuth token sync) | `~/.claude/.credentials.json`, system Keychain | 🚫 N/A | macOS filesystem access required | — |
| **12. macOS-Only APIs (No iOS Equivalent)** | | | | |
| Menu bar (`NSStatusItem` + `NSPopover`) | `MenuBarManager`, `StatusBarUIManager` | 🚫 N/A | iOS uses tab bar + widget | — |
| Launch at login (`SMAppService`) | `LaunchAtLoginManager` | 🚫 N/A | No iOS concept | — |
| Keyboard shortcuts (`NSEvent`) | `ShortcutManager`, `ShortcutsSettingsView` | 🚫 N/A | Not needed on iOS | — |
| AppKit `NSSound` for custom alert sounds | `NotificationManager` | 🚫 N/A | iOS uses `UNNotificationSound` | — |
| Debug network log view | `NetworkLoggerService`, `DebugNetworkLogView` | 🚫 N/A | Developer tool | — |
| Peak hours analysis | `PeakHoursService`, `PeakHoursPopoverView` | 🚫 N/A | macOS-specific scheduling insight | — |
| Usage history snapshots + export (CSV/JSON) | `UsageHistoryService`, `UsageHistoryView` | ❌ Missing | Not macOS-specific — valuable on iOS; records per-reset usage peaks for trend analysis | L |

---

## MVP Recommendation

Highest-value missing items to complete first, in priority order:

1. **Notification dispatch** — All infrastructure is already built (settings model, threshold toggles, permission flow). A `NotificationManager.checkAndNotify()` call inside `AppState.refresh()`, plus a deduplication store, makes the entire notification feature functional. Highest return per line of code in the codebase.

2. **API Console billing** — The `APIUsage` model, `APICostSource`, and `consoleBase` URL constant are all ported. Remaining work: (a) add `apiUsage: APIUsage?` to iOS `Profile`, (b) port `ClaudeAPIService+ConsoleAPI.swift`, (c) add a console API key entry UI, (d) add a billing card to `UsageView`.

3. **Notification deduplication + session reset alert** — Must ship with dispatch. Without dedup, alerts fire on every 30-second refresh. The `sentNotifications` Set in `UserDefaults` is a one-evening implementation.

---

## Quick Wins

🟡 Partial items that are close to done:

- **Custom notification thresholds UI** — `NotificationSettings.customThresholds: [Int]` already exists in the model. Needs a `+` button and a stepper/text field in `SettingsView.notificationThresholdsView`.
- **"Show remaining %" toggle** — `ClaudeUsage.remainingPercentage` already exists. One `AppStorage` bool + swap in `UsageView.usageCard(...)`.
- **Week: show tokens option** — `weeklyTokensUsed` is already calculated and stored. One Picker in `SettingsView` toggles the label format in `UsageView`.
- **Offline indicator** — `NetworkMonitor.isConnected` is already wired. A `.overlay` banner on `UsageView` when disconnected takes ~10 lines.

---

## Suggested Drops

Items not yet marked 🚫 N/A that should be dropped for iOS:

- **CLI OAuth credentials sync** — Reads macOS filesystem paths and the macOS system Keychain. No iOS path exists. The browser session key flow is the primary iOS credential method.
- **Auto-start sessions** — `BGAppRefreshTask` is heavily throttled (typically once per several hours, no guarantee), and the use case (keeping a session alive overnight) doesn't apply to mobile. Recommend marking 🚫 N/A.
- **In-app language picker** — iOS handles app language via Settings.app → Language. Strings should eventually move to `.lproj` files for system localisation, but no in-app picker needed.
- **Peak hours service** — Analyses desktop usage patterns. Not meaningful on mobile. Mark 🚫 N/A.
- **Profile funny-name generator** — Nice personality touch; not worth prioritising.
