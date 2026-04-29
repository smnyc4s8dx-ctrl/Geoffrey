# Geoffrey — User Stories

> **Generated:** 2026-03-24
> **Format:** Action → Expectation → Code Section(s)
> **Total:** 500 user stories across 18 functional domains

---

## Table of Contents

1. [Onboarding & First Run](#1-onboarding--first-run) (US-001 – US-015)
2. [LM Studio Connection Settings](#2-lm-studio-connection-settings) (US-016 – US-040)
3. [Project Management](#3-project-management) (US-041 – US-075)
4. [Project Wizard](#4-project-wizard) (US-076 – US-130)
5. [World Templates](#5-world-templates) (US-131 – US-155)
6. [Import & Export](#6-import--export) (US-156 – US-210)
7. [Duplicate Resolution](#7-duplicate-resolution) (US-211 – US-235)
8. [Navigation & Layout](#8-navigation--layout) (US-236 – US-260)
9. [Card Browser & Sidebar](#9-card-browser--sidebar) (US-261 – US-290)
10. [Location Cards](#10-location-cards) (US-291 – US-325)
11. [Character Cards](#11-character-cards) (US-326 – US-370)
12. [Lore Cards](#12-lore-cards) (US-371 – US-400)
13. [Scene Inspector](#13-scene-inspector) (US-401 – US-430)
14. [Narrative Modes](#14-narrative-modes) (US-431 – US-450)
15. [Dialogue Canvas](#15-dialogue-canvas) (US-451 – US-475)
16. [Prompt Input & Sending](#16-prompt-input--sending) (US-476 – US-490)
17. [AI Response & Streaming](#17-ai-response--streaming) (US-491 – US-500)
18. [Context Assembly & Token Estimation](#18-context-assembly--token-estimation) (cross-cutting)

---

## 1. Onboarding & First Run

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-001 | Launch app for the first time | Onboarding sheet appears | `MainView.swift` — `@AppStorage("hasCompletedOnboarding")`, `.onAppear` |
| US-002 | View onboarding welcome screen (step 0) | See app name, description, and "Next" button | `OnboardingView.swift` — step 0 body |
| US-003 | Click "Next" on welcome step | Advance to connection setup step with animation | `OnboardingView.swift` — `currentStep += 1` with `.easeInOut` |
| US-004 | Click "Back" on connection step | Return to welcome screen | `OnboardingView.swift` — `currentStep -= 1` |
| US-005 | View connection setup step (step 1) | See server URL and model name text fields | `OnboardingView.swift` — step 1 body |
| US-006 | Enter custom server URL | URL field updates to user value | `OnboardingView.swift` — `baseURLString` state binding |
| US-007 | Enter model name override | Model name field updates | `OnboardingView.swift` — `modelName` state binding |
| US-008 | Click "Test Connection" | Connection test begins; status indicator shows result | `OnboardingView.swift` → `LMStudioClient.checkHealth()` |
| US-009 | Connection test succeeds | Green checkmark and success message appear | `OnboardingView.swift` — `connectionStatus` updated |
| US-010 | Connection test fails | Red X and error message appear | `OnboardingView.swift` — `connectionStatus` updated |
| US-011 | Click "Test Response Format" after successful connection | Format compliance test runs against model | `OnboardingView.swift` → `LMStudioClient.testFormatCompliance()` |
| US-012 | Format test passes | Success message with tag analysis shown | `LMStudioClient.swift` — `FormatTestResult` |
| US-013 | Format test fails | Warning shown with details on what failed | `LMStudioClient.swift` — `FormatTestResult.passed == false` |
| US-014 | Click "Next" to final onboarding step (step 2) | See summary and "Get Started" button | `OnboardingView.swift` — step 2 body |
| US-015 | Click "Get Started" | Onboarding dismissed; `hasCompletedOnboarding` set true | `OnboardingView.swift` — `isPresented = false` |

---

## 2. LM Studio Connection Settings

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-016 | Open Settings window (macOS menu) | LM Studio settings view appears | `GeoffreyApp.swift` — `Settings { LMStudioSettingsView() }` |
| US-017 | Open settings from status bar icon | OnboardingView sheet appears in settings mode | `MainView.swift` — gear icon button, `showingOnboarding = true` |
| US-018 | Edit server URL in settings | `@AppStorage` value persists across launches | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioBaseURL")` |
| US-019 | Edit model name in settings | Model name persists across launches | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioModelName")` |
| US-020 | Adjust temperature slider | Value updates (0–2, step 0.05); persists | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioTemperature")` |
| US-021 | Set temperature to 0 | Deterministic output expected from LLM | `LMStudioClient.swift` — `temperature` property |
| US-022 | Set temperature to 2.0 (max) | Highly creative/random output expected | `LMStudioClient.swift` — `temperature` property |
| US-023 | Set max tokens via text field | Integer value persists | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioMaxTokens")` |
| US-024 | Set max tokens to a small value (e.g. 128) | Short responses from LLM | `LMStudioClient.swift` — `maxTokens` sent in API request |
| US-025 | Set max tokens to a large value (e.g. 8192) | Long responses allowed from LLM | `LMStudioClient.swift` — `maxTokens` sent in API request |
| US-026 | Adjust top-P slider | Value updates (0–1, step 0.05); persists | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioTopP")` |
| US-027 | Adjust repetition penalty slider | Value updates (1–2, step 0.05); persists | `LMStudioSettingsView.swift` — `@AppStorage("lmStudioRepetitionPenalty")` |
| US-028 | Change settings while generation is active | Next prompt uses updated values | `LMStudioClient.swift` — `updateSettings()` actor method |
| US-029 | Enter invalid URL in server field | Connection monitor shows disconnected | `ConnectionMonitor.swift` — `checkNow()` returns false |
| US-030 | Enter URL without port | Connection attempt uses URL as-is | `LMStudioClient.swift` — `baseURL` property |
| US-031 | Leave model name empty | LM Studio uses its default loaded model | `LMStudioClient.swift` — `modelName: String?` (nil = server default) |
| US-032 | View connection status in status bar | Colored dot indicator shows connected/disconnected | `MainView.swift` — `ConnectionMonitor.isConnected` display |
| US-033 | Connection drops mid-session | Status dot turns red; next send shows error | `ConnectionMonitor.swift` — `startPolling()` every 5 seconds |
| US-034 | LM Studio comes back online | Status dot turns green automatically | `ConnectionMonitor.swift` — `pollingTask` detects recovery |
| US-035 | Restart LM Studio with different model | Next prompt uses new model (if name blank) | `LMStudioClient.swift` — server-side model selection |
| US-036 | View last connection check time | `lastChecked` timestamp available | `ConnectionMonitor.swift` — `lastChecked: Date?` |
| US-037 | Force-check connection status | Immediate health check triggered | `ConnectionMonitor.swift` — `checkNow()` async |
| US-038 | Start connection polling on app launch | Periodic checks begin automatically | `ConnectionMonitor.swift` — `startPolling()` |
| US-039 | Close app | Connection polling stops | `ConnectionMonitor.swift` — `stopPolling()` |
| US-040 | Settings persist across app restarts | All `@AppStorage` values reload on launch | `LMStudioSettingsView.swift` — `@AppStorage` declarations |

---

## 3. Project Management

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-041 | View project picker on launch | List of existing projects shown, or empty state | `WorldPickerView.swift` — `projects` array display |
| US-042 | See project creation date | Each project row shows `createdAt` | `Project.swift` — `createdAt: Date` |
| US-043 | Click "New Project" button | Project wizard sheet opens | `WorldPickerView.swift` — `showingWizard = true` |
| US-044 | Select an existing project | Project loads; world and session are initialized | `WorldPickerView.swift` — `onSelect` callback → `MainView.swift` — `setupSession(for:)` |
| US-045 | Delete a project via trash icon | Confirmation alert appears | `WorldPickerView.swift` — trash button, `.alert` modifier |
| US-046 | Confirm project deletion | Project removed from database; list refreshes | `WorldPickerView.swift` → `WorldViewModel.deleteProject()` |
| US-047 | Cancel project deletion | Alert dismissed; no change | `WorldPickerView.swift` — `.alert` cancel action |
| US-048 | Delete the currently selected project | Returns to project picker; selection cleared | `WorldViewModel.swift` — `deleteProject()` clears `selectedProject` |
| US-049 | Delete a non-selected project | Only that project removed; current selection intact | `WorldViewModel.swift` — `deleteProject()` conditional clear |
| US-050 | Project deletion cascades to world | World and all child data deleted | `Project.swift` — `@Relationship(deleteRule: .cascade)` |
| US-051 | World deletion cascades to locations | All locations deleted with world | `World.swift` — `@Relationship(deleteRule: .cascade)` for locations |
| US-052 | World deletion cascades to characters | All characters deleted with world | `World.swift` — `@Relationship(deleteRule: .cascade)` for characters |
| US-053 | World deletion cascades to lore cards | All lore cards deleted with world | `World.swift` — `@Relationship(deleteRule: .cascade)` for loreCards |
| US-054 | World deletion cascades to sessions | All sessions and exchanges deleted | `World.swift` — `@Relationship(deleteRule: .cascade)` for sessions |
| US-055 | Session deletion cascades to exchanges | All exchanges in session deleted | `Session.swift` — `@Relationship(deleteRule: .cascade)` for exchanges |
| US-056 | Location deletion cascades to residencies | CharacterResidency links deleted | `Location.swift` — `@Relationship(deleteRule: .cascade)` for residencies |
| US-057 | Location deletion cascades to lore links | LoreLink associations deleted | `Location.swift` — `@Relationship(deleteRule: .cascade)` for loreLinks |
| US-058 | Location deletion cascades to state history | StateHistory entries deleted | `Location.swift` — `@Relationship(deleteRule: .cascade)` for stateHistory |
| US-059 | Character deletion cascades to relationships | CharacterRelationship entries deleted | `StoryCharacter.swift` — `@Relationship(deleteRule: .cascade)` for relationships |
| US-060 | Character deletion cascades to residencies | CharacterResidency links deleted | `StoryCharacter.swift` — `@Relationship(deleteRule: .cascade)` for residencies |
| US-061 | LoreCard deletion cascades to trigger rules | TriggerRule entries deleted | `LoreCard.swift` — `@Relationship(deleteRule: .cascade)` for triggerRules |
| US-062 | LoreCard deletion cascades to lore links | LoreLink associations deleted | `LoreCard.swift` — `@Relationship(deleteRule: .cascade)` for loreLinks |
| US-063 | Click "Export" on a project | File save dialog appears | `WorldPickerView.swift` — export button action |
| US-064 | Export project without images | Saves as `.geoffrey.json` | `CardExporter.swift` — `exportWorld()` → JSON encode |
| US-065 | Export project with images | Saves as `.geoffrey.zip` (JSON + images) | `CardExporter.swift` — `exportWorldAsZip()` |
| US-066 | Click "Import" button | File picker opens for `.json` or `.zip` | `WorldPickerView.swift` — `.fileImporter` modifier |
| US-067 | Import a valid `.geoffrey.json` | ImportOptionsView appears with parsed data | `CardExporter.swift` — `parseExportedWorld()` |
| US-068 | Import a valid `.geoffrey.zip` | ImportOptionsView appears with parsed data + images | `CardExporter.swift` — `parseExportedWorldFromZip()` |
| US-069 | Import corrupted file | Error message displayed | `CardExporter.swift` — `ImportError` thrown |
| US-070 | Import file with unsupported version | Version error shown | `CardExporter.swift` — `ImportError.unsupportedVersion` |
| US-071 | Navigate back to project picker | Click house icon in header bar | `MainView.swift` — house button clears `selectedProject` + `currentSession` |
| US-072 | View empty project list | Empty state shown with creation prompt | `WorldPickerView.swift` — empty state body |
| US-073 | View templates section | Pre-built world templates listed | `WorldPickerView.swift` — `TemplateLibrary.allTemplates` |
| US-074 | Create project from wizard completion | New project appears in list and is selected | `WorldPickerView.swift` — wizard `onComplete` callback |
| US-075 | Multiple projects exist | All projects listed in order | `WorldPickerView.swift` — `ForEach` over projects |

---

## 4. Project Wizard

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-076 | Open project wizard | Step 0 shown: project/world name fields | `ProjectWizardView.swift` — `currentStep == 0` |
| US-077 | Enter project name | `projectName` state updates | `ProjectWizardView.swift` — TextField binding |
| US-078 | Enter world name | `worldName` state updates | `ProjectWizardView.swift` — TextField binding |
| US-079 | Click "Import from File" in step 0 | File importer opens for `.geoffrey.json` | `ProjectWizardView.swift` — `.fileImporter` |
| US-080 | Import valid file in wizard | Fields populated from imported data | `ProjectWizardView.swift` — import handling |
| US-081 | Click "Next" on step 0 | Advance to step 1 (system preamble) | `ProjectWizardView.swift` — `currentStep = 1` |
| US-082 | "Next" disabled when project name empty | Button greyed out | `ProjectWizardView.swift` — `.disabled` condition |
| US-083 | View system preamble step (step 1) | TextEditor for preamble + example shown | `ProjectWizardView.swift` — step 1 body |
| US-084 | Enter system preamble text | `systemPreamble` state updates | `ProjectWizardView.swift` — TextEditor binding |
| US-085 | Click "Show Different Example" on preamble | New random example preamble displayed | `ProjectWizardView.swift` → `ExampleContent.randomPreamble()` |
| US-086 | Click "Next" on step 1 | Advance to step 2 (add locations) | `ProjectWizardView.swift` — `currentStep = 2` |
| US-087 | Click "Back" on step 1 | Return to step 0 | `ProjectWizardView.swift` — `currentStep -= 1` |
| US-088 | View add locations step (step 2) | Location name, description, atmosphere fields shown | `ProjectWizardView.swift` — step 2 body |
| US-089 | Enter location name | `locationName` state updates | `ProjectWizardView.swift` — TextField binding |
| US-090 | Enter location description | `locationDescription` state updates | `ProjectWizardView.swift` — TextEditor binding |
| US-091 | Enter location atmosphere | `locationAtmosphere` state updates | `ProjectWizardView.swift` — TextField binding |
| US-092 | Click "Save & Add Another" for location | Location saved to pending list; fields cleared | `ProjectWizardView.swift` — save and reset logic |
| US-093 | Click "Show Different Example" on location | New random location example displayed | `ProjectWizardView.swift` → `ExampleContent.randomLocation()` |
| US-094 | Click "Next" on step 2 | Advance to step 3 (add characters); saves pending location | `ProjectWizardView.swift` — `currentStep = 3` |
| US-095 | Click "Back" on step 2 | Return to step 1 | `ProjectWizardView.swift` — `currentStep -= 1` |
| US-096 | Click "Skip to Project" on step 2 | Saves current if filled, creates project, finishes wizard | `ProjectWizardView.swift` — skip logic |
| US-097 | View add characters step (step 3) | Character name, role, persona, voice fields shown | `ProjectWizardView.swift` — step 3 body |
| US-098 | Enter character name | `characterName` state updates | `ProjectWizardView.swift` — TextField binding |
| US-099 | Enter character role | `characterRole` state updates | `ProjectWizardView.swift` — TextField binding |
| US-100 | Enter character persona | `characterPersona` state updates | `ProjectWizardView.swift` — TextEditor binding |
| US-101 | Enter character voice sample | `characterVoice` state updates | `ProjectWizardView.swift` — TextEditor binding |
| US-102 | Click "Save & Add Another" for character | Character saved to pending list; fields cleared | `ProjectWizardView.swift` — save and reset logic |
| US-103 | Click "Show Different Example" on character | New random character example displayed | `ProjectWizardView.swift` → `ExampleContent.randomCharacter()` |
| US-104 | Click "Next" on step 3 | Advance to step 4 (add lore); saves pending character | `ProjectWizardView.swift` — `currentStep = 4` |
| US-105 | Click "Back" on step 3 | Return to step 2 | `ProjectWizardView.swift` — `currentStep -= 1` |
| US-106 | Click "Skip to Project" on step 3 | Creates project with all data entered so far | `ProjectWizardView.swift` — skip logic |
| US-107 | View add lore step (step 4) | Lore title, content, tags fields shown | `ProjectWizardView.swift` — step 4 body |
| US-108 | Enter lore title | `loreTitle` state updates | `ProjectWizardView.swift` — TextField binding |
| US-109 | Enter lore content | `loreContent` state updates | `ProjectWizardView.swift` — TextEditor binding |
| US-110 | Enter lore tags (comma-separated) | `loreTags` state updates | `ProjectWizardView.swift` — TextField binding |
| US-111 | Click "Save & Add Another" for lore | Lore saved to pending list; fields cleared | `ProjectWizardView.swift` — save and reset logic |
| US-112 | Click "Show Different Example" on lore | New random lore example displayed | `ProjectWizardView.swift` → `ExampleContent.randomLore()` |
| US-113 | Click "Finish" on step 4 | Project created with all accumulated data | `ProjectWizardView.swift` — `onComplete` callback |
| US-114 | Click "Back" on step 4 | Return to step 3 | `ProjectWizardView.swift` — `currentStep -= 1` |
| US-115 | Click "Skip to Project" on step 4 | Creates project, skipping remaining lore | `ProjectWizardView.swift` — skip logic |
| US-116 | Cancel wizard at any step | Sheet dismissed; no project created | `ProjectWizardView.swift` — `onCancel` callback |
| US-117 | Create project with only name (skip all) | Minimal project with empty world created | `ProjectWizardView.swift` — skip-to-project from step 1 |
| US-118 | Add multiple locations before advancing | All locations accumulated in pending list | `ProjectWizardView.swift` — `pendingLocations` array |
| US-119 | Add multiple characters before advancing | All characters accumulated in pending list | `ProjectWizardView.swift` — `pendingCharacters` array |
| US-120 | Add multiple lore cards before finishing | All lore accumulated in pending list | `ProjectWizardView.swift` — `pendingLore` array |
| US-121 | Example content refreshes each click | Different example each time (15 options per type) | `ExampleContent.swift` — random selection from arrays |
| US-122 | Preamble examples are genre-diverse | 15 genre preambles available | `ExampleContent.swift` — `randomPreamble()` |
| US-123 | Location examples are varied | 15 location examples available | `ExampleContent.swift` — `randomLocation()` |
| US-124 | Character examples are varied | 15 character examples available | `ExampleContent.swift` — `randomCharacter()` |
| US-125 | Lore examples are varied | 15 lore examples available | `ExampleContent.swift` — `randomLore()` |
| US-126 | Wizard preserves data when navigating back | Previously entered data still present | `ProjectWizardView.swift` — `@State` persistence |
| US-127 | Wizard creates World linked to Project | 1:1 Project→World relationship | `Project.swift` — `world: World?` relationship |
| US-128 | Wizard inserts locations into world | Locations linked to world | `World.swift` — `locations: [Location]` |
| US-129 | Wizard inserts characters into world | Characters linked to world | `World.swift` — `characters: [StoryCharacter]` |
| US-130 | Wizard inserts lore into world | Lore cards linked to world | `World.swift` — `loreCards: [LoreCard]` |

---

## 5. World Templates

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-131 | View template list | 5 pre-built templates shown with descriptions | `TemplateLibrary.swift` — `allTemplates` |
| US-132 | Click "Load" on Blackwood Affair template | Crime mystery world created (3 loc, 4 char, 3 lore) | `TemplateLibrary.swift` — `blackwoodAffair` |
| US-133 | Click "Load" on Gilded Hearth template | Fantasy tavern world created (2 loc, 3 char, 2 lore) | `TemplateLibrary.swift` — `gildedHearth` |
| US-134 | Click "Load" on Signal Drift template | Sci-fi world created (3 loc, 3 char, 3 lore) | `TemplateLibrary.swift` — `signalDrift` |
| US-135 | Click "Load" on Ink and Ashes template | 1940s noir world created (3 loc, 3 char, 2 lore) | `TemplateLibrary.swift` — `inkAndAshes` |
| US-136 | Click "Load" on Ledger Keeper template | Dark fantasy world created (3 loc, 3 char, 3 lore) | `TemplateLibrary.swift` — `theLeadgerKeeper` |
| US-137 | Template loads and selects project | World ready for immediate use | `TemplateLibrary.swift` — `createWorld()` → `WorldPickerView.swift` `onSelect` |
| US-138 | Template locations have descriptions | Each location has stateLabel, description, atmosphere | `TemplateLibrary.swift` — `LocationTemplate` fields |
| US-139 | Template characters have personas | Each character has role, persona, voiceSample | `TemplateLibrary.swift` — `CharacterTemplate` fields |
| US-140 | Template characters have psychological state | Mental state pre-filled | `TemplateLibrary.swift` — `psychologicalState` field |
| US-141 | Template lore cards have tags | Tags and priority pre-set | `TemplateLibrary.swift` — `LoreCardTemplate` fields |
| US-142 | Template lore cards have priorities | High/Normal/Background set per template | `TemplateLibrary.swift` — `priority: LorePriority` |
| US-143 | Template includes system preamble | Genre-appropriate preamble pre-written | `TemplateLibrary.swift` — `systemPreamble` field |
| US-144 | Export a template | Template saves as `.geoffrey.json` file | `WorldPickerView.swift` — export button on template row |
| US-145 | Template world saved to SwiftData | All entities persisted | `TemplateLibrary.swift` — `context.insert()` + `context.save()` |
| US-146 | Template creates new Project wrapper | Project wraps the template world | `WorldPickerView.swift` — project creation from template |
| US-147 | Template characters default locked state | `stateUpdatePermission` defaults to `.locked` | `StoryCharacter.swift` — init default |
| US-148 | Template locations default locked state | `stateUpdatePermission` defaults to `.locked` | `Location.swift` — init default |
| US-149 | Template lore defaults locked state | `stateUpdatePermission` defaults to `.locked` | `LoreCard.swift` — init default |
| US-150 | Template world has empty sessions array | No pre-existing dialogue | `World.swift` — `sessions: [Session] = []` |
| US-151 | Loaded template immediately usable | User can start dialogue right away | `MainView.swift` — `setupSession(for:)` |
| US-152 | Template name shown in project list | Project appears with template-derived name | `WorldPickerView.swift` — project row display |
| US-153 | Template description shown before loading | User can read summary before committing | `WorldPickerView.swift` — template description display |
| US-154 | Multiple templates can be loaded | Each creates independent project | `TemplateLibrary.swift` — `createWorld()` creates new each time |
| US-155 | Template data is editable after loading | All cards can be modified post-creation | Card editor views — standard edit flows |

---

## 6. Import & Export

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-156 | Export world as JSON | Encoded `ExportedWorld` saved | `CardExporter.swift` — `exportWorld()` |
| US-157 | Exported JSON includes version | `geoffreyVersion` field present | `ExportModels.swift` — `ExportedWorld.geoffreyVersion` |
| US-158 | Exported JSON includes timestamp | `exportedAt` date field present | `ExportModels.swift` — `ExportedWorld.exportedAt` |
| US-159 | Export includes all locations | Every location serialized | `CardExporter.swift` — `exportWorld()` maps locations |
| US-160 | Export includes all characters | Every character serialized | `CardExporter.swift` — `exportWorld()` maps characters |
| US-161 | Export includes all lore cards | Every lore card serialized | `CardExporter.swift` — `exportWorld()` maps loreCards |
| US-162 | Export includes location state fields | condition, accessibility, atmosphere exported | `ExportModels.swift` — `ExportedLocation` fields |
| US-163 | Export includes character state fields | All 6 state fields exported | `ExportModels.swift` — `ExportedCharacter` fields |
| US-164 | Export includes lore state fields | currency, revelationStatus, scopeChange exported | `ExportModels.swift` — `ExportedLoreCard` fields |
| US-165 | Export world with images triggers ZIP | ZIP format used when images present | `CardExporter.swift` — `worldHasImages()` check |
| US-166 | ZIP export contains `world.json` | JSON file at root of archive | `CardExporter.swift` — `exportWorldAsZip()` |
| US-167 | ZIP export contains image files | Images in `locations/` and `characters/` subdirs | `CardExporter.swift` — `exportWorldAsZip()` image writing |
| US-168 | Image filenames are sanitized | Special chars removed from names | `CardExporter.swift` — `sanitizeFilename()` |
| US-169 | Exported location images referenced | `imageFilename` field in JSON matches ZIP path | `ExportModels.swift` — `ExportedLocation.imageFilename` |
| US-170 | Exported character images referenced | `imageFilename` field in JSON matches ZIP path | `ExportModels.swift` — `ExportedCharacter.imageFilename` |
| US-171 | Import JSON file | World created from parsed data | `CardExporter.swift` — `importWorld(from:into:)` |
| US-172 | Import ZIP file | World created with images restored | `CardExporter.swift` — `importWorldFromZip()` |
| US-173 | Format auto-detected on import | JSON vs ZIP determined by magic bytes | `CardExporter.swift` — `detectFileFormat()` |
| US-174 | Import creates all locations | Locations inserted into new world | `CardExporter.swift` — `insertLocation()` |
| US-175 | Import creates all characters | Characters inserted into new world | `CardExporter.swift` — `insertCharacter()` |
| US-176 | Import creates all lore cards | Lore inserted into new world | `CardExporter.swift` — `insertLore()` |
| US-177 | Import restores image data | `imageData` set from ZIP files | `CardExporter.swift` — image loading in import |
| US-178 | Choose "Create as New World" on import | New independent world created | `ImportOptionsView.swift` — `onCreateNew` callback |
| US-179 | Choose "Merge into Existing World" | Merge flow begins with selected world | `ImportOptionsView.swift` — `onMergeInto` callback |
| US-180 | Cancel import | No changes made; sheet dismissed | `ImportOptionsView.swift` — `onCancel` callback |
| US-181 | Merge detects duplicate locations | Name-matching conflicts found | `CardExporter.swift` — `detectDuplicates()` location check |
| US-182 | Merge detects duplicate characters | Name-matching conflicts found | `CardExporter.swift` — `detectDuplicates()` character check |
| US-183 | Merge detects duplicate lore | Title-matching conflicts found | `CardExporter.swift` — `detectDuplicates()` lore check |
| US-184 | Merge with no conflicts | All items imported directly | `CardExporter.swift` — `mergeIntoWorld()` no conflicts path |
| US-185 | Merge with conflicts | DuplicateResolverView shown | `WorldPickerView.swift` — conflict resolution flow |
| US-186 | "Keep Existing" resolution | Imported item skipped | `CardExporter.swift` — `mergeIntoWorld()` `.keepExisting` |
| US-187 | "Replace" resolution | Existing item overwritten with import | `CardExporter.swift` — `mergeIntoWorld()` `.replace` |
| US-188 | "Keep Both" resolution | Import renamed with "(imported)" suffix | `CardExporter.swift` — `mergeIntoWorld()` `.keepBoth` |
| US-189 | Merge preserves existing non-conflicting items | Untouched items remain intact | `CardExporter.swift` — selective merge logic |
| US-190 | Parse exported world for preview | Data parsed without DB insertion | `CardExporter.swift` — `parseExportedWorld()` |
| US-191 | Parse ZIP for preview | ZIP parsed without DB insertion | `CardExporter.swift` — `parseExportedWorldFromZip()` |
| US-192 | Extract images from ZIP separately | Images loaded for merge flow | `CardExporter.swift` — `extractImages()` |
| US-193 | Import with images into merge | Images applied per resolution | `CardExporter.swift` — `mergeIntoWorld()` with images param |
| US-194 | Import missing `world.json` in ZIP | `ImportError.missingWorldJSON` thrown | `CardExporter.swift` — ZIP validation |
| US-195 | Import unsupported version | `ImportError.unsupportedVersion` shown | `CardExporter.swift` — version check |
| US-196 | Export preserves character relationships | Relationships included in export | `ExportModels.swift` — relationship data |
| US-197 | Export preserves lore tags | Tag arrays serialized | `ExportModels.swift` — `ExportedLoreCard.tags` |
| US-198 | Export preserves lore priority | Priority enum value serialized | `ExportModels.swift` — `ExportedLoreCard.priority` |
| US-199 | Duplicate conflict shows existing summary | Summary of current item displayed | `CardExporter.swift` — `summarize(existing...)` |
| US-200 | Duplicate conflict shows incoming summary | Summary of imported item displayed | `CardExporter.swift` — `summarize(imported...)` |
| US-201 | Location summary includes key fields | Name + description snippet | `CardExporter.swift` — `summarize(existingLocation:)` |
| US-202 | Character summary includes key fields | Name + role snippet | `CardExporter.swift` — `summarize(existingCharacter:)` |
| US-203 | Lore summary includes key fields | Title + content snippet | `CardExporter.swift` — `summarize(existingLore:)` |
| US-204 | Imported world name preserved | World name from export file used | `ExportModels.swift` — `ExportedWorld.name` |
| US-205 | Imported preamble preserved | System preamble from export used | `ExportModels.swift` — `ExportedWorld.systemPreamble` |
| US-206 | Recursive file search in ZIP | Nested image files found | `CardExporter.swift` — `findFile(named:in:)` |
| US-207 | Temporary directory cleanup after ZIP export | No temp files left behind | `CardExporter.swift` — `exportWorldAsZip()` cleanup |
| US-208 | State update permissions exported | Permission enums serialized | `ExportModels.swift` — stateUpdatePermission fields |
| US-209 | Character voice samples exported | Voice text included | `ExportModels.swift` — `ExportedCharacter.voiceSample` |
| US-210 | Character notes exported | Notes field included | `ExportModels.swift` — `ExportedCharacter.notes` |

---

## 7. Duplicate Resolution

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-211 | View duplicate resolver | First conflict displayed with details | `DuplicateResolverView.swift` — `currentIndex = 0` |
| US-212 | See conflict counter | "1 of N" indicator shown | `DuplicateResolverView.swift` — counter display |
| US-213 | See card type of conflict | Location/Character/Lore type shown | `DuplicateConflict.cardType` → `ImportTypes.swift` |
| US-214 | See conflicting item name | Item name prominently displayed | `DuplicateConflict.name` |
| US-215 | See existing item summary | Current item description shown | `DuplicateConflict.existingSummary` |
| US-216 | See incoming item summary | Import item description shown | `DuplicateConflict.incomingSummary` |
| US-217 | Select "Keep Existing" for conflict | Segmented picker updates to `.keepExisting` | `DuplicateResolverView.swift` — Picker binding |
| US-218 | Select "Replace" for conflict | Segmented picker updates to `.replace` | `DuplicateResolverView.swift` — Picker binding |
| US-219 | Select "Keep Both" for conflict | Segmented picker updates to `.keepBoth` | `DuplicateResolverView.swift` — Picker binding |
| US-220 | Navigate to next conflict | Right chevron advances `currentIndex` | `DuplicateResolverView.swift` — right arrow button |
| US-221 | Navigate to previous conflict | Left chevron decrements `currentIndex` | `DuplicateResolverView.swift` — left arrow button |
| US-222 | At first conflict, back is disabled | Left chevron greyed out | `DuplicateResolverView.swift` — `.disabled(currentIndex == 0)` |
| US-223 | At last conflict, forward is disabled | Right chevron greyed out | `DuplicateResolverView.swift` — `.disabled` condition |
| US-224 | Click "Keep All Existing" bulk action | All conflicts set to `.keepExisting` | `DuplicateResolverView.swift` — bulk menu action |
| US-225 | Click "Replace All" bulk action | All conflicts set to `.replace` | `DuplicateResolverView.swift` — bulk menu action |
| US-226 | Click "Keep All (Both Copies)" bulk action | All conflicts set to `.keepBoth` | `DuplicateResolverView.swift` — bulk menu action |
| US-227 | Click "Cancel" | Import cancelled; no changes | `DuplicateResolverView.swift` — `onCancel` callback |
| US-228 | Click "Apply & Import" | Resolutions applied; merge executed | `DuplicateResolverView.swift` — `onApply` callback |
| US-229 | Resolution persists per conflict | Each conflict tracks its own resolution | `DuplicateConflict.resolution` mutable property |
| US-230 | Default resolution | Each conflict starts with a default | `ImportTypes.swift` — `DuplicateResolution` default |
| US-231 | Resolution names user-friendly | "Keep Existing", "Replace", "Keep Both" | `DuplicateResolution.displayName` |
| US-232 | Card type icon shown | SF Symbol per card type | `ImportTypes.swift` — `CardType.icon` |
| US-233 | Card type display name shown | "Location", "Character", "Lore" | `ImportTypes.swift` — `CardType.displayName` |
| US-234 | Animation on conflict navigation | Smooth transition between conflicts | `DuplicateResolverView.swift` — `.animation` modifier |
| US-235 | All conflicts must be resolved | "Apply" available after any selection | `DuplicateResolverView.swift` — button availability |

---

## 8. Navigation & Layout

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-236 | View 3-column layout | Sidebar + Canvas + Inspector visible | `MainView.swift` — `NavigationSplitView` with `.all` visibility |
| US-237 | Resize window | Minimum size enforced | `GeoffreyApp.swift` — `Theme.minWindowWidth/Height` |
| US-238 | Default window size on launch | Reasonable default dimensions | `GeoffreyApp.swift` — `Theme.defaultWindowWidth/Height` |
| US-239 | Toggle sidebar visibility | Sidebar column collapses/expands | `MainView.swift` — `columnVisibility` state |
| US-240 | View header bar | World name and navigation controls shown | `MainView.swift` — custom header bar |
| US-241 | See world name in header | Current world name displayed prominently | `MainView.swift` — header with `world.name` |
| US-242 | Click house icon in header | Return to project picker | `MainView.swift` — clears `worldVM.selectedProject` |
| US-243 | View connection status dot | Bottom-left colored dot indicator | `MainView.swift` — connection status display |
| US-244 | Green dot when connected | LM Studio reachable | `ConnectionMonitor.swift` — `isConnected == true` |
| US-245 | Red dot when disconnected | LM Studio unreachable | `ConnectionMonitor.swift` — `isConnected == false` |
| US-246 | Click connection status | Opens settings/onboarding sheet | `MainView.swift` — settings gear action |
| US-247 | Error banner appears on error | Dismissible error at top of canvas | `MainView.swift` / `DialogueCanvasView.swift` — `errorMessage` display |
| US-248 | Dismiss error banner | Click "Dismiss" button | `MainView.swift` — `sessionVM.errorMessage = nil` |
| US-249 | ProgressView shown while loading | Spinner during VM initialization | `MainView.swift` — `ProgressView()` fallback |
| US-250 | Theme colors consistent | Orange=location, Teal=character, Purple=lore | `Theme.swift` — color constants |
| US-251 | Serif font for manuscript content | Body text uses serif design | `Theme.swift` — `manuscriptFont` |
| US-252 | Canvas background distinct | Slightly transparent text background | `Theme.swift` — `canvasBackground` |
| US-253 | Committed exchanges visually distinct | Orange-tinted accent | `Theme.swift` — `committedAccent` |
| US-254 | Consistent corner radii | Bubbles and cards use Theme values | `Theme.swift` — `bubbleCornerRadius`, `cardCornerRadius` |
| US-255 | Consistent spacing | Sections use Theme spacing values | `Theme.swift` — `sectionSpacing`, `cardPadding` |
| US-256 | Avatar size consistent | 48pt avatars throughout | `Theme.swift` — `avatarSize` |
| US-257 | App runs sandboxed | Entitlements restrict capabilities | `Geoffrey.entitlements` — `app-sandbox = true` |
| US-258 | Network access allowed | Can reach LM Studio | `Geoffrey.entitlements` — `network.client = true` |
| US-259 | User file access allowed | Can import/export files | `Geoffrey.entitlements` — `files.user-selected.read-write = true` |
| US-260 | SwiftData container initialized on launch | All 11 model types registered | `GeoffreyApp.swift` — `Schema([...])` |

---

## 9. Card Browser & Sidebar

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-261 | View card browser in sidebar | Tabbed view with Locations/Characters/Lore | `CardBrowserView.swift` — `Picker` with `CardTab` |
| US-262 | Switch to Locations tab | Location list displayed | `CardBrowserView.swift` — `selectedTab: .locations` |
| US-263 | Switch to Characters tab | Character list displayed | `CardBrowserView.swift` — `selectedTab: .characters` |
| US-264 | Switch to Lore tab | Lore card list displayed | `CardBrowserView.swift` — `selectedTab: .lore` |
| US-265 | Type in search field | Cards filtered by search text | `CardBrowserView.swift` — `searchText` binding |
| US-266 | Clear search field | All cards shown again | `CardBrowserView.swift` — empty `searchText` |
| US-267 | Click "New Card" button | Editor sheet opens for current tab type | `CardBrowserView.swift` — new card action |
| US-268 | New card on Locations tab | LocationEditorView opens in create mode | `CardBrowserView.swift` → `LocationEditorView` |
| US-269 | New card on Characters tab | CharacterEditorView opens in create mode | `CardBrowserView.swift` → `CharacterEditorView` |
| US-270 | New card on Lore tab | LoreEditorView opens in create mode | `CardBrowserView.swift` → `LoreEditorView` |
| US-271 | Click a location in list | Location selected (triggers scene change) | `LocationListView.swift` — `onSelect` callback |
| US-272 | Right-click location | Context menu with Edit/Delete | `LocationListView.swift` — `.contextMenu` |
| US-273 | Click "Edit" in location context menu | LocationEditorView opens in edit mode | `LocationListView.swift` — edit sheet |
| US-274 | Click "Delete" in location context menu | Location deleted from world | `LocationListView.swift` — `modelContext.delete()` |
| US-275 | Right-click character | Context menu with Edit/Delete | `CharacterListView.swift` — `.contextMenu` |
| US-276 | Click "Edit" in character context menu | CharacterEditorView opens in edit mode | `CharacterListView.swift` — edit sheet |
| US-277 | Click "Delete" in character context menu | Character deleted from world | `CharacterListView.swift` — `modelContext.delete()` |
| US-278 | Right-click lore card | Context menu with Edit/Delete | `LoreListView.swift` — `.contextMenu` |
| US-279 | Click "Edit" in lore context menu | LoreEditorView opens in edit mode | `LoreListView.swift` — edit sheet |
| US-280 | Click "Delete" in lore context menu | Lore card deleted from world | `LoreListView.swift` — `modelContext.delete()` |
| US-281 | Card row shows name | Card name displayed in row | `CardRowView.swift` — name label |
| US-282 | Card row shows type color | Color-coded per card type | `CardRowView.swift` — Theme color |
| US-283 | Location row shows state label | State label visible | `CardRowView.swift` — subtitle display |
| US-284 | Character row shows role | Role visible in row | `CardRowView.swift` — subtitle display |
| US-285 | Lore row shows priority | Priority badge visible | `CardRowView.swift` — priority display |
| US-286 | Empty location list | Empty state or prompt to create | `LocationListView.swift` — empty handling |
| US-287 | Empty character list | Empty state or prompt to create | `CharacterListView.swift` — empty handling |
| US-288 | Empty lore list | Empty state or prompt to create | `LoreListView.swift` — empty handling |
| US-289 | Search filters across visible fields | Name/title matching | `CardBrowserView.swift` — filter logic |
| US-290 | New card appears in list after save | List refreshes via SwiftData query | SwiftData `@Query` auto-refresh |

---

## 10. Location Cards

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-291 | Open location editor (create mode) | Empty form with all fields | `LocationEditorView.swift` — create init |
| US-292 | Open location editor (edit mode) | Fields pre-filled from existing location | `LocationEditorView.swift` — edit init with location |
| US-293 | Enter location name | Name field updates | `LocationEditorView.swift` — `name` state |
| US-294 | Enter state label | State label updates (default: "Default") | `LocationEditorView.swift` — `stateLabel` state |
| US-295 | Enter description text | Description TextEditor updates | `LocationEditorView.swift` — `descriptionText` state |
| US-296 | Enter condition description | State field updates | `LocationEditorView.swift` — `conditionDescription` state |
| US-297 | Enter accessibility value | State field updates (default: "Open") | `LocationEditorView.swift` — `accessibility` state |
| US-298 | Enter atmosphere | State field updates | `LocationEditorView.swift` — `atmosphere` state |
| US-299 | Set state update permission to Locked | Manual-only state changes | `LocationEditorView.swift` → `StateUpdatePermission.locked` |
| US-300 | Set state update permission to AI-Suggested | AI can suggest state changes | `LocationEditorView.swift` → `StateUpdatePermission.aiSuggested` |
| US-301 | Set state update permission to AI-Managed | AI can freely update state | `LocationEditorView.swift` → `StateUpdatePermission.aiManaged` |
| US-302 | Enter notes | Notes TextEditor updates | `LocationEditorView.swift` — `notes` state |
| US-303 | Drag image onto location placeholder | Image processed and shown as preview | `LocationEditorView.swift` — `.onDrop` → `ImageUtilities.resizeImage()` |
| US-304 | Click "Choose Image" | File picker opens for PNG/JPEG | `LocationEditorView.swift` — `.fileImporter` |
| US-305 | Select image from file picker | Image loaded, resized, displayed | `LocationEditorView.swift` → `ImageUtilities.loadImage()` |
| US-306 | Click "Paste" for image | Clipboard image applied | `LocationEditorView.swift` → `ImageUtilities.imageFromPasteboard()` |
| US-307 | Click "Remove" on image | Image data cleared; placeholder returns | `LocationEditorView.swift` — `imageData = nil` |
| US-308 | Image resized on load | Max 1024px dimension maintained | `ImageUtilities.swift` — `resizeImage(maxDimension: 1024)` |
| US-309 | Image stored externally | Large data uses external storage | `Location.swift` — `@Attribute(.externalStorage) var imageData` |
| US-310 | Click "Cancel" in editor | Sheet dismissed; no changes saved | `LocationEditorView.swift` — dismiss action |
| US-311 | Click "Create" (new location) | Location inserted into world and saved | `LocationEditorView.swift` — `modelContext.insert()` + save |
| US-312 | Click "Save" (existing location) | Location properties updated and saved | `LocationEditorView.swift` — property assignment + save |
| US-313 | Location linked to world | `world` relationship set | `Location.swift` — `world: World?` |
| US-314 | Location has residencies array | Character presence tracking ready | `Location.swift` — `residencies: [CharacterResidency]` |
| US-315 | Location has lore links array | Lore association tracking ready | `Location.swift` — `loreLinks: [LoreLink]` |
| US-316 | Location has state history array | Change tracking ready | `Location.swift` — `stateHistory: [StateHistory]` |
| US-317 | State history tracks field changes | fieldName, previous, new, source, timestamp | `StateHistory.swift` — all properties |
| US-318 | State history defaults to "manual" source | Unless AI-managed | `StateHistory.swift` — `source: String = "manual"` |
| US-319 | State history auto-timestamps | `timestamp` set to `.now` | `StateHistory.swift` — init |
| US-320 | Residency tracks presence | `isPresent` boolean on link | `CharacterResidency.swift` — `isPresent: Bool` |
| US-321 | LoreLink connects location to lore | Join model with both references | `LoreLink.swift` — `location` + `loreCard` |
| US-322 | Location name required | Cannot save without name | `LocationEditorView.swift` — validation |
| US-323 | Image from drag maintains aspect ratio | Resize preserves proportions | `ImageUtilities.swift` — aspect ratio calculation |
| US-324 | PNG data output from image processing | Consistent format | `ImageUtilities.swift` — `pngData()` conversion |
| US-325 | Thread-safe image resizing | CGContext used instead of NSImage drawing | `ImageUtilities.swift` — CGContext approach |

---

## 11. Character Cards

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-326 | Open character editor (create mode) | Empty form with all fields | `CharacterEditorView.swift` — create init |
| US-327 | Open character editor (edit mode) | Fields pre-filled from existing character | `CharacterEditorView.swift` — edit init |
| US-328 | Enter character name | Name field updates | `CharacterEditorView.swift` — `name` state |
| US-329 | Enter character role | Role field updates | `CharacterEditorView.swift` — `role` state |
| US-330 | Enter persona text | Persona TextEditor updates | `CharacterEditorView.swift` — `persona` state |
| US-331 | Enter voice sample text | Voice TextEditor updates | `CharacterEditorView.swift` — `voiceSample` state |
| US-332 | Enter vitality status | Default: "Alive" | `CharacterEditorView.swift` — `vitalityStatus` state |
| US-333 | Enter psychological state | Mental state field updates | `CharacterEditorView.swift` — `psychologicalState` state |
| US-334 | Enter knowledge state | Knowledge field updates | `CharacterEditorView.swift` — `knowledgeState` state |
| US-335 | Enter roleplay posture | Posture field updates | `CharacterEditorView.swift` — `roleplayPosture` state |
| US-336 | Enter narrative presence | Presence field updates | `CharacterEditorView.swift` — `narrativePresence` state |
| US-337 | Enter current state | General state field updates | `CharacterEditorView.swift` — `currentState` state |
| US-338 | Set character state update permission | Picker updates enum value | `CharacterEditorView.swift` — `stateUpdatePermission` |
| US-339 | Enter character notes | Notes TextEditor updates | `CharacterEditorView.swift` — `notes` state |
| US-340 | Drag image onto character avatar | Avatar image updates | `CharacterEditorView.swift` — `.onDrop` handler |
| US-341 | Click "Choose Image" for character | File picker opens for PNG/JPEG | `CharacterEditorView.swift` — `.fileImporter` |
| US-342 | Select character image from picker | Image loaded and displayed in avatar area | `CharacterEditorView.swift` → `ImageUtilities.loadImage()` |
| US-343 | Click "Paste" for character image | Clipboard image applied to avatar | `CharacterEditorView.swift` → `ImageUtilities.imageFromPasteboard()` |
| US-344 | Click "Remove" character image | Avatar reverts to initials display | `CharacterEditorView.swift` — `imageData = nil` |
| US-345 | Character avatar shows initials when no image | Colored circle with first letters of name | `CharacterAvatarView.swift` — initials extraction |
| US-346 | Character avatar shows color | Teal accent color used | `CharacterAvatarView.swift` — `Theme.characterColor` |
| US-347 | Character avatar size consistent | 48pt diameter | `CharacterAvatarView.swift` — `Theme.avatarSize` |
| US-348 | Character avatar shows image when set | Image fills circle | `CharacterAvatarView.swift` — image display branch |
| US-349 | Character image stored externally | Large data uses external storage | `StoryCharacter.swift` — `@Attribute(.externalStorage) var imageData` |
| US-350 | Click "Cancel" in character editor | Sheet dismissed; no changes | `CharacterEditorView.swift` — dismiss action |
| US-351 | Click "Create" (new character) | Character inserted and saved | `CharacterEditorView.swift` — insert + save |
| US-352 | Click "Save" (existing character) | Character updated and saved | `CharacterEditorView.swift` — update + save |
| US-353 | Character linked to world | `world` relationship set | `StoryCharacter.swift` — `world: World?` |
| US-354 | Character has relationships array | Relationship tracking ready | `StoryCharacter.swift` — `relationships: [CharacterRelationship]` |
| US-355 | Character has residencies array | Location presence tracking ready | `StoryCharacter.swift` — `residencies: [CharacterResidency]` |
| US-356 | Relationship stores target by name | String reference, not model reference | `CharacterRelationship.swift` — `targetCharacterName: String` |
| US-357 | Relationship stores description | Freeform text | `CharacterRelationship.swift` — `relationshipDescription` |
| US-358 | Relationship linked to owner character | Inverse relationship maintained | `CharacterRelationship.swift` — `ownerCharacter` |
| US-359 | Six distinct character state fields | Vitality, psychological, knowledge, roleplay, narrative, current | `StoryCharacter.swift` — 6 state properties |
| US-360 | State update permission controls AI access | Locked, AI-Suggested, AI-Managed | `CardEnums.swift` — `StateUpdatePermission` |
| US-361 | Locked permission means manual only | AI cannot modify state fields | `StateUpdatePermission.locked` |
| US-362 | AI-Suggested means soft recommendations | AI can propose but not auto-apply | `StateUpdatePermission.aiSuggested` |
| US-363 | AI-Managed means full autonomy | AI can update state fields freely | `StateUpdatePermission.aiManaged` |
| US-364 | Permission display names are user-friendly | "Locked (Manual Only)", etc. | `CardEnums.swift` — `displayName` computed |
| US-365 | Default vitality is "Alive" | Characters start alive | `StoryCharacter.swift` — init default |
| US-366 | Default permission is locked | Safe default | `StoryCharacter.swift` — init default `.locked` |
| US-367 | Voice sample informs AI tone | Included in context for LLM | `ContextAssembler.swift` — character context building |
| US-368 | Persona informs AI characterization | Core personality sent to LLM | `ContextAssembler.swift` — character context building |
| US-369 | Character name used for [Tag] attribution | Names used in response parsing | `ResponseParser.swift` — `speakingNames` matching |
| US-370 | Character name required | Cannot save without name | `CharacterEditorView.swift` — validation |

---

## 12. Lore Cards

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-371 | Open lore editor (create mode) | Empty form with all fields | `LoreEditorView.swift` — create init |
| US-372 | Open lore editor (edit mode) | Fields pre-filled from existing lore | `LoreEditorView.swift` — edit init |
| US-373 | Enter lore title | Title field updates | `LoreEditorView.swift` — `title` state |
| US-374 | Enter lore content | Content TextEditor updates | `LoreEditorView.swift` — `content` state |
| US-375 | Enter comma-separated tags | Tags text field updates | `LoreEditorView.swift` — `tagsText` state |
| US-376 | Tags parsed from comma-separated string | String split into array on save | `LoreEditorView.swift` — tag parsing logic |
| US-377 | Set priority to High | Lore prioritized in context assembly | `LoreEditorView.swift` — `priority: .high` |
| US-378 | Set priority to Normal | Standard inclusion priority | `LoreEditorView.swift` — `priority: .normal` |
| US-379 | Set priority to Background | Low priority, may be omitted if context is full | `LoreEditorView.swift` — `priority: .background` |
| US-380 | Priority display names user-friendly | "High", "Normal", "Background" | `CardEnums.swift` — `LorePriority.displayName` |
| US-381 | Enter currency value | Default: "Current" | `LoreEditorView.swift` — `currency` state |
| US-382 | Enter revelation status | Default: "Universal" | `LoreEditorView.swift` — `revelationStatus` state |
| US-383 | Enter scope change | Scope change field updates | `LoreEditorView.swift` — `scopeChange` state |
| US-384 | Set lore state update permission | Picker updates enum | `LoreEditorView.swift` — `stateUpdatePermission` |
| US-385 | Click "Cancel" in lore editor | Sheet dismissed; no changes | `LoreEditorView.swift` — dismiss action |
| US-386 | Click "Create" (new lore) | Lore card inserted and saved | `LoreEditorView.swift` — insert + save |
| US-387 | Click "Save" (existing lore) | Lore card updated and saved | `LoreEditorView.swift` — update + save |
| US-388 | Lore linked to world | `world` relationship set | `LoreCard.swift` — `world: World?` |
| US-389 | Lore has trigger rules array | Trigger tracking ready | `LoreCard.swift` — `triggerRules: [TriggerRule]` |
| US-390 | Trigger rule has type and value | Configurable activation condition | `TriggerRule.swift` — `ruleType` + `ruleValue` |
| US-391 | Trigger rule linked to lore card | Inverse relationship maintained | `TriggerRule.swift` — `loreCard` |
| US-392 | Lore has lore links array | Location association tracking ready | `LoreCard.swift` — `loreLinks: [LoreLink]` |
| US-393 | Default lore priority is Normal | Safe default | `LoreCard.swift` — init default `.normal` |
| US-394 | Default lore permission is Locked | Safe default | `LoreCard.swift` — init default `.locked` |
| US-395 | Default currency is "Current" | Lore considered up-to-date | `LoreCard.swift` — init default |
| US-396 | Default revelation is "Universal" | All characters aware | `LoreCard.swift` — init default |
| US-397 | Lore content sent to LLM | Active lore included in context | `ContextAssembler.swift` — lore context building |
| US-398 | Lore priority affects context ordering | High priority lore included first | `ContextAssembler.swift` — `LoreContext.priority` |
| US-399 | Lore title required | Cannot save without title | `LoreEditorView.swift` — validation |
| US-400 | Tags stored as string array | `[String]` in SwiftData | `LoreCard.swift` — `tags: [String]` |

---

## 13. Scene Inspector

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-401 | View scene inspector panel | Right column shows active scene state | `SceneInspectorView.swift` — inspector layout |
| US-402 | See active location section | Current location name and details shown | `ActiveLocationSection.swift` — location display |
| US-403 | See "No location" when none set | Placeholder shown | `ActiveLocationSection.swift` — nil handling |
| US-404 | Select location from sidebar | Inspector updates to show new location | `SceneInspectorViewModel.swift` — `setLocation()` |
| US-405 | Location change updates present characters | Characters from residencies loaded | `SceneInspectorViewModel.swift` — `setLocation()` residency query |
| US-406 | Location change clears speaking characters | Speaking list reset on location change | `SceneInspectorViewModel.swift` — `speakingCharacters = []` |
| US-407 | Location change loads linked lore | Associated lore cards activated | `SceneInspectorViewModel.swift` — `setLocation()` lore links |
| US-408 | See present characters section | List of characters at current location | `PresentCharactersSection.swift` — character list |
| US-409 | Toggle character presence (eye icon) | Add/remove character from scene | `PresentCharactersSection.swift` → `SceneInspectorViewModel.toggleCharacterPresence()` |
| US-410 | Add character to presence | Character appears in present list | `SceneInspectorViewModel.swift` — `presentCharacters.append()` |
| US-411 | Remove character from presence | Character removed; also removed from speaking | `SceneInspectorViewModel.swift` — remove + speaking cleanup |
| US-412 | Toggle character speaking (mic icon) | Enable/disable character voice in scene | `PresentCharactersSection.swift` → `SceneInspectorViewModel.toggleCharacterSpeaking()` |
| US-413 | Enable speaking auto-adds to present | Character made present if not already | `SceneInspectorViewModel.swift` — auto-add logic |
| US-414 | Speaking characters get [Name] tags | LLM response uses character tags | `ContextAssembler.swift` — `buildSceneDirection()` |
| US-415 | Presence/speaking synced to SessionVM | Inspector state pushed to session | `SceneInspectorViewModel.swift` — `syncToSession()` |
| US-416 | See active lore section | List of activated lore cards | `ActiveLoreSection.swift` — lore list |
| US-417 | Remove lore card (minus button) | Lore deactivated from scene | `ActiveLoreSection.swift` → `SceneInspectorViewModel.removeLoreCard()` |
| US-418 | Add lore card from menu | Select lore from "Add Lore" dropdown | `ActiveLoreSection.swift` → `SceneInspectorViewModel.addLoreCard()` |
| US-419 | Added lore synced to SessionVM | Lore included in next context assembly | `SceneInspectorViewModel.swift` — `syncToSession()` |
| US-420 | See system preamble section | Editable TextEditor for world preamble | `SystemPreambleSection.swift` — preamble editor |
| US-421 | Edit system preamble | Text changes update world.systemPreamble | `SystemPreambleSection.swift` — `.onChange` modifier |
| US-422 | Preamble changes persist | SwiftData saves preamble update | `SystemPreambleSection.swift` — world property update |
| US-423 | Enter director's note | TextEditor in inspector updates | `SceneInspectorView.swift` → `sessionVM.directorsNote` |
| US-424 | Director's note included in context | Note sent to LLM as stage direction | `ContextAssembler.swift` — `directorsNote` parameter |
| US-425 | Director's note persists within session | Value maintained across sends | `SessionViewModel.swift` — `directorsNote: String` |
| US-426 | Only present characters eligible for speaking | Speaking is subset of present | `SceneInspectorViewModel.swift` — subset enforcement |
| US-427 | Lore not duplicated if already active | Cannot add same lore twice | `SceneInspectorViewModel.swift` — duplicate check |
| US-428 | Scene state survives re-render | `@Observable` VM persists across view updates | `SceneInspectorViewModel.swift` — `@Observable` |
| US-429 | Inspector shows character avatars | Avatar view used in present characters | `PresentCharactersSection.swift` — `CharacterAvatarView` |
| US-430 | Inspector lore shows priority badge | Priority level visible | `ActiveLoreSection.swift` — priority display |

---

## 14. Narrative Modes

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-431 | View current narrative mode in header | Mode label shown (e.g., "Director") | `MainView.swift` — mode display in header |
| US-432 | Click mode label to open menu | Dropdown with all 4 modes + character submenu | `MainView.swift` — `Menu` with mode options |
| US-433 | Select Director mode | Stage-direction prompting style | `NarrativeMode.swift` — `.director` |
| US-434 | Director mode icon | Megaphone SF Symbol | `NarrativeMode.swift` — `"megaphone"` |
| US-435 | Director mode description | "Direct the scene — your prompts are stage directions" | `NarrativeMode.swift` — `.director` description |
| US-436 | Select Author mode | Prose-continuation prompting style | `NarrativeMode.swift` — `.author` |
| US-437 | Author mode icon | Pencil SF Symbol | `NarrativeMode.swift` — `"pencil.line"` |
| US-438 | Author mode description | "Write prose — your input continues the narrative" | `NarrativeMode.swift` — `.author` description |
| US-439 | Select Game Master mode | World-narration prompting style | `NarrativeMode.swift` — `.gameMaster` |
| US-440 | Game Master mode icon | Crown SF Symbol | `NarrativeMode.swift` — `"crown"` |
| US-441 | Game Master mode description | "Narrate the world — your input is world narration" | `NarrativeMode.swift` — `.gameMaster` description |
| US-442 | Select Character mode via submenu | Character submenu lists world characters | `MainView.swift` — "Play as Character" submenu |
| US-443 | Pick specific character to play as | `narrativeMode` = `.character`, `playerCharacter` set | `MainView.swift` — character selection action |
| US-444 | Character mode icon | Person fill SF Symbol | `NarrativeMode.swift` — `"person.fill"` |
| US-445 | Character mode description | "Play as a character — your input is in-character" | `NarrativeMode.swift` — `.character` description |
| US-446 | Switching to non-character mode clears player | `playerCharacter = nil` | `MainView.swift` — mode change action |
| US-447 | Mode affects prompt framing | `SessionViewModel.sendPrompt()` reads `narrativeMode` | `SessionViewModel.swift` — prompt framing logic |
| US-448 | Director mode wraps prompt as stage direction | Prompt framed as "[Director's instruction: ...]" | `SessionViewModel.swift` — mode-specific framing |
| US-449 | Character mode tags prompt with character name | Prompt attributed to player character | `SessionViewModel.swift` — character mode framing |
| US-450 | Mode selection persists within session | Value maintained until changed | `SessionViewModel.swift` — `narrativeMode` state |

---

## 15. Dialogue Canvas

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-451 | View dialogue canvas | Center column shows exchange history | `DialogueCanvasView.swift` — ScrollView with exchanges |
| US-452 | See exchange bubbles | Each exchange rendered as bubble | `ExchangeBubbleView.swift` — bubble layout |
| US-453 | User messages aligned/styled distinctly | Visual distinction from assistant messages | `ExchangeBubbleView.swift` — role-based styling |
| US-454 | Assistant messages show character segments | Parsed [Name] tags shown with attribution | `ExchangeBubbleView.swift` — `ResponseParser` segments |
| US-455 | Narration segments styled differently | Narration vs character speech visual distinction | `ExchangeBubbleView.swift` — `SegmentType` styling |
| US-456 | Click "View Raw" on assistant exchange | Raw LLM response shown in sheet | `DialogueCanvasView.swift` — `RawResponseSheet` |
| US-457 | Click "Done" on raw view sheet | Sheet dismissed | `DialogueCanvasView.swift` — `RawResponseSheet.onDismiss` |
| US-458 | Click commit button on exchange | Exchange marked as committed | `DialogueCanvasView.swift` → `SessionViewModel.toggleCommitted()` |
| US-459 | Committed exchange styled with accent | Orange accent color applied | `ExchangeBubbleView.swift` — `Theme.committedAccent` |
| US-460 | Click commit button on committed exchange | Exchange unmarked (back to working) | `SessionViewModel.swift` — `toggleCommitted()` toggles |
| US-461 | Committed exchanges in context as history | Sent as prior messages to LLM | `ContextAssembler.swift` — `committedExchanges` |
| US-462 | Working exchanges in context as recent | Sent as working dialogue to LLM | `ContextAssembler.swift` — `workingDialogue` |
| US-463 | Click "Edit" on exchange | Editor sheet opens with current content | `DialogueCanvasView.swift` — `ExchangeEditorSheet` |
| US-464 | Edit exchange content in sheet | TextEditor shows current content | `DialogueCanvasView.swift` — editor TextEditor |
| US-465 | Click "Save" in exchange editor | Content updated and saved | `DialogueCanvasView.swift` → `SessionViewModel.updateExchangeContent()` |
| US-466 | Click "Cancel" in exchange editor | Sheet dismissed; no changes | `DialogueCanvasView.swift` — editor cancel |
| US-467 | Click "Delete" on exchange | Exchange removed from session | `DialogueCanvasView.swift` → `SessionViewModel.deleteExchange()` |
| US-468 | Exchanges sorted by order index | Chronological display order | `SessionViewModel.swift` — `sortedExchanges` |
| US-469 | Exchange stores character name | Attribution preserved | `Exchange.swift` — `characterName: String?` |
| US-470 | Exchange stores role (user/assistant) | Message direction tracked | `Exchange.swift` — `role: String` |
| US-471 | Exchange stores creation time | Timestamp preserved | `Exchange.swift` — `createdAt: Date` |
| US-472 | Exchange supports retcon reference | Can link to replaced exchange | `Exchange.swift` — `retconnedFrom: Exchange?` |
| US-473 | Session resumes on re-entry | Most recent session loaded | `SessionViewModel.swift` — `ensureSession()` |
| US-474 | New session created if none exists | First session auto-created | `SessionViewModel.swift` — `ensureSession()` fallback |
| US-475 | Canvas scrolls to bottom on new exchange | Latest content visible | `DialogueCanvasView.swift` — scroll behavior |

---

## 16. Prompt Input & Sending

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-476 | Type in prompt input | TextEditor captures input | `PromptInputView.swift` — `text` binding |
| US-477 | Click send button | Prompt sent to LLM | `PromptInputView.swift` — `onSend` callback |
| US-478 | Press Cmd+Return | Prompt sent via keyboard shortcut | `PromptInputView.swift` — `.keyboardShortcut` |
| US-479 | Send disabled when empty | Button greyed out for blank input | `PromptInputView.swift` — `.disabled` condition |
| US-480 | Send disabled during generation | Button greyed out while streaming | `PromptInputView.swift` — `isGenerating` check |
| US-481 | Stop button shown during generation | Cancel control visible | `PromptInputView.swift` — stop button toggle |
| US-482 | Click stop button | Generation cancelled | `PromptInputView.swift` — `onCancel` callback |
| US-483 | Prompt cleared after send | Input field emptied | `DialogueCanvasView.swift` — `promptText = ""` after send |
| US-484 | User exchange created on send | Exchange with role="user" persisted | `SessionViewModel.swift` — `sendPrompt()` user exchange |
| US-485 | Assistant exchange created for response | Exchange with role="assistant" persisted | `SessionViewModel.swift` — `sendPrompt()` assistant exchange |
| US-486 | Order index auto-incremented | Each exchange gets sequential index | `SessionViewModel.swift` — `orderIndex` calculation |
| US-487 | Empty/whitespace-only prompt rejected | No action on blank send | `SessionViewModel.swift` — `trimmingCharacters` guard |
| US-488 | Error on send shows message | `errorMessage` populated if send fails | `SessionViewModel.swift` — error handling in `sendPrompt()` |
| US-489 | Prompt mode visible near input | Current mode indicated in input area | `PromptInputView.swift` — mode indicator |
| US-490 | Input area appropriately sized | TextEditor has reasonable min/max height | `PromptInputView.swift` — frame constraints |

---

## 17. AI Response & Streaming

| ID | User Action | Expectation | Code Section(s) |
|----|------------|-------------|------------------|
| US-491 | Send prompt triggers streaming | `isGenerating` becomes true; tokens stream in | `SessionViewModel.swift` → `LMStudioClient.complete()` |
| US-492 | Streaming text updates in real-time | `streamingText` updated per SSE chunk | `SessionViewModel.swift` — `streamingText` accumulation |
| US-493 | Response parsed for character tags | `[Name]` tags extracted into segments | `ResponseParser.swift` — `parseSegments()` |
| US-494 | [Narrator] tag recognized | Narration segments identified | `ResponseParser.swift` — `"Narrator"` case-insensitive match |
| US-495 | Untagged text treated as narration | Preamble text before first tag is narration | `ResponseParser.swift` — fallback handling |
| US-496 | Leading colons stripped from segments | Content cleaned after `[Name]:` | `ResponseParser.swift` — colon stripping |
| US-497 | Cancel generation mid-stream | `streamingTask` cancelled; partial response kept | `SessionViewModel.swift` — `cancelGeneration()` |
| US-498 | LLM error during streaming | Error message displayed to user | `SessionViewModel.swift` — error catch in streaming |
| US-499 | SSE parsing handles `data: [DONE]` | Stream completion recognized | `LMStudioClient.swift` — SSE event parsing |
| US-500 | Context messages built before each send | Full world state assembled | `SessionViewModel.swift` → `ContextAssembler.assemble()` |

---

## 18. Context Assembly & Token Estimation (Cross-Cutting)

> These are not direct user actions but underpin observable behavior across the app.

| Ref | Behavior | User-Visible Effect | Code Section(s) |
|-----|----------|---------------------|------------------|
| XC-01 | World context bundled as user message | Avoids "system" role for local model compatibility | `ContextAssembler.swift` — user role for context |
| XC-02 | Assistant acknowledges context | Fake assistant message confirms understanding | `ContextAssembler.swift` — "Understood..." message |
| XC-03 | Location context formatted | Name, description, condition, atmosphere included | `ContextAssembler.swift` — `buildLocationContext()` |
| XC-04 | Character context formatted | Name, role, persona, voice, state, relationships | `ContextAssembler.swift` — `buildCharacterContext()` |
| XC-05 | Scene direction built | Present/speaking characters + format instructions | `ContextAssembler.swift` — `buildSceneDirection()` |
| XC-06 | Token count estimated | Approximate count shown in UI | `TokenEstimator.swift` — `estimate()` heuristic |
| XC-07 | Token estimation uses char/4 heuristic | Simple but fast approximation | `TokenEstimator.swift` — `max(1, text.count / 4)` |
| XC-08 | Per-message overhead included | 4 tokens per message added | `TokenEstimator.swift` — message overhead |
| XC-09 | Token counter displayed | Current context size visible | `TokenCounterView.swift` — counter display |
| XC-10 | Context includes director's note | Stage directions sent when present | `ContextAssembler.swift` — `directorsNote` injection |

---

*End of document — 500 user stories + 10 cross-cutting behaviors*
