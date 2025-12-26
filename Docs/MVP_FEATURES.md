# MonkScan MVP — Two-Track Plan (UI Prototype → Production)

Goal: Ship a beautiful, intuitive, production-ready scanner app.
Core flow: Library → Scan → Crop/Perspective → Enhance → Pages → Export
No backend. Offline-first.

## 🎯 Current Status (Updated: Dec 26, 2025)
**Track A:** ✅ COMPLETE (All UI screens built)
**Track B:** 🔄 ~90% COMPLETE (Core features done, polish in progress)

### Next Priority:
**B5 - Export Testing:** Verify PDF, JPG, and Text exports work correctly from the app

Locked decisions:
- Navigation: Bottom tab bar (Library / Scan / Settings)
- Capture: Camera + Photo import
- Organization: Tags
- Export: PDF + JPG + Text
- OCR: Included
- Flash + Auto-capture: Implement
- Delight: Auto file naming template
- Persistence: FileManager + JSON metadata (extensible)

Hard rules (always):
- Use existing design system: NBColors, NBType, NBTheme.
- Use components in /Components. No random inline styling.
- If a new UI pattern repeats, create a component in /Components.
- Keep feature code in /Features/<Feature>/.
- Each step must compile and run before moving on.
- Prefer protocols + services so Track B is easy.

---

## Architecture (designed for extensibility)

### Domain models (shared)
- ScanDocument
  - id: UUID
  - title: String
  - createdAt, updatedAt: Date
  - tags: [String]
  - pages: [ScanPage]
  - ocrText: String? (aggregated)
- ScanPage
  - id: UUID
  - originalImagePath: String? (Track B)
  - processedImagePath: String? (Track B)
  - uiImage: UIImage? (Track A only, in-memory)
  - rotation: Int
  - cropEdits: CropEdits?
  - filterEdits: FilterEdits?

### Scan session (in-progress flow state)
- ScanSession
  - draftTitle: String (default “Scan YYYY-MM-DD HHmm”)
  - draftTags: [String]
  - pages: [ScanPage]
  - settings snapshot (optional)

### Services (protocols first)
Define protocols now (Track A uses stubs, Track B implements real):
- PhotoImportService
- OCRService
- ExportService (PDF/JPG/Text)
- DocumentStore (persistence)

Note: Document scanning uses VNDocumentCameraViewController (VisionKit), which handles document detection, cropping, perspective correction, and enhancement automatically. No separate DocumentDetectionService or ImageProcessingService needed.

Rule: UI talks to protocols, not concrete implementations.

---

## Screen Map (Tabs + Flow)

Tabs:
1) LibraryTab
2) ScanTab
3) SettingsTab

Scan flow (inside Scan tab as NavigationStack or modal stack):
ScanView → PagesView → ExportView → Done → Library

Note: Using VNDocumentCameraViewController for scanning, which handles document detection, cropping, perspective correction, and enhancement automatically. CropView and EnhanceView are no longer needed in the flow.

Important:
- The scan pipeline should NOT be reachable by random deep links in MVP.
- Prevent accidental tab switching from nuking a draft:
  - Either keep draft state in a shared ScanSessionStore (ObservableObject)
  - Or confirm before discarding.

---

# TRACK A — UI Prototype (Clickable app, fast) ✅ COMPLETE

Goal: Build all screens with real UI + navigation + state,
using STUB services so everything works end-to-end.

**Status:** UI screens are complete. All views are implemented and navigation works. Moving to production feature implementation (Track B).

## A1 — App Shell + Tabs
Create:
- /Features/Shell/AppTabView.swift (TabView: Library / Scan / Settings)
- /Features/Shell/RootCoordinator.swift (optional) or simple shared stores
Update MonkScanApp.swift → AppTabView.

Acceptance:
- Tab bar visible and styled.
- Each tab loads a screen.

## A2 — Create all screens (UI only)
Create these views (use NB components):
- /Features/Library/LibraryView.swift (already exists; wire to store later)
- /Features/Scan/ScanView.swift (camera placeholder UI + controls)
- /Features/Edit/CropView.swift (image preview + crop UI placeholder)
- /Features/Edit/EnhanceView.swift (preset buttons + slider)
- /Features/Edit/PagesView.swift (thumbnails list + reorder placeholder)
- /Features/Export/ExportView.swift (format selection + share button placeholder)
- /Features/Settings/SettingsView.swift (toggles + defaults UI)

Acceptance:
- Every screen renders.
- Styling consistent (no new colors/fonts).
- Navigation works through entire scan flow with dummy state.

## A3 — Shared ScanSession state (real shape)
Create:
- /Features/Scan/ScanSessionStore.swift (ObservableObject)
Holds:
- current ScanSession
- methods: startNewSession(), addPage(image), updateEdits, completeExport()

Acceptance:
- You can add placeholder pages and see them in PagesView.
- Title/tags exist in state (even if UI is basic).

## A4 — Stub services (so UI behaves)
Create /Services/Stubs/:
- StubCameraService: returns a placeholder UIImage
- StubPhotoImportService: returns placeholder UIImage
- StubDocumentDetectionService: returns default rectangle
- StubImageProcessingService: returns same image
- StubOCRService: returns lorem text
- StubExportService: returns success
- InMemoryDocumentStore: keeps docs while app runs

Acceptance:
- “Capture” and “Import” both add a page.
- “OCR” returns text in ExportView.
- Completing “Done” adds a document to Library (in-memory).

## A5 — Library driven by InMemoryDocumentStore
Implement Library interactions using store:
- list docs
- search title/tags/ocrText
- rename doc
- delete doc
- doc detail view (optional) to re-export

Acceptance:
- Full loop: scan flow → Done → appears in Library.

## A6 — Settings UI + defaults plumbing (stubbed)
Use UserDefaults via a small SettingsStore:
- default export format
- OCR language (UI only for now)
- auto filename toggle
- flash default
- auto-capture default

Acceptance:
- Settings changes persist and affect UI defaults.

TRACK A DONE when:
- The app feels “real” end-to-end and looks consistent.
- No camera/Vision/PDF/FileManager yet, but UX is validated.

---

# TRACK B — Production Implementations (Current Focus)

Goal: Implement production-ready features step-by-step.
UI is complete, now building real functionality one feature at a time.

## B1 — Photo import (real) ✅ COMPLETE
Implement PhotoImportService using PhotosPicker.
Replace stub in dependency injection.
**Status:** PhotosPicker integrated in ScanView. Multiple photo import works.
Acceptance:
- ✅ Selecting a photo creates a real page and continues flow.

## B2 — Document scanner (real) ✅ COMPLETE
Integrate VNDocumentCameraViewController into ScanView.
- Vision automatically handles: document detection, cropping, perspective correction, and enhancement
- Handle document scanner results (multiple pages)
- Remove/update CropView and EnhanceView (no longer needed in flow)
- New flow: ScanView → PagesView → ExportView

**Status:** DocumentScannerView using VNDocumentCameraViewController is fully integrated.
Acceptance:
- ✅ Document scanner opens and captures pages.
- ✅ Returns processed images (already cropped and enhanced).
- ✅ Multiple pages can be captured in one session.

## B3 — Pages management (real behaviors) ✅ COMPLETE
Implement:
- reorder using SwiftUI drag
- delete
- rotate
- add page returns to Scan and appends

**Status:** PagesView has full drag/drop reordering, delete, and page editing capabilities.
Acceptance:
- ✅ Export order matches PagesView order.

## B4 — OCR (real) ✅ COMPLETE
Implement OCRService using Vision text recognition.
Store:
- per-page text (optional)
- aggregated doc text for search and export

**Status:** OCRService implemented using Vision framework. OCR results viewable in PageEditView.
Acceptance:
- ✅ Export Text contains OCR output.
- ✅ Library search matches OCR.

## B5 — Export (real) ⚠️ NEEDS TESTING
Implement ExportService:
- PDF export (multi-page)
- JPG export (share multiple images)
- Text export (.txt)
- Share sheet + Save to Files

**Status:** Export UI exists in ExportView. Need to verify real export implementations work.
Acceptance:
- ⏳ Exports work from simulator device. (NEEDS TESTING)

## B6 — Persistence (FileManager + JSON) (real) ✅ COMPLETE
Implement DocumentStore:
- FileDocumentStore:
  - directory per document id
  - page images saved to disk
  - metadata.json per document
- Load on app start
- CRUD: rename, delete, update tags, update page order

**Status:** FileDocumentStore fully implemented with file-based persistence.
Acceptance:
- ✅ Close app → reopen → documents remain.
- ✅ Delete removes files.

## B8 — Tag Management (Production-ready) ✅ COMPLETE
**Added:** Custom tag system for document organization.
- Custom tags with global persistence (UserDefaults)
- 14 default common tags initialized on first launch
- Add/delete tags globally
- Full-width tag picker with delete functionality
- Works in ExportView and EditMetadataView

Acceptance:
- ✅ Users can create and delete custom tags
- ✅ Tags persist across app launches
- ✅ Tags searchable in Library

## B7 — Polish (still MVP, but production-ready) 🔄 IN PROGRESS
- Permissions UX (camera/photos) ⏳
- Empty states (no docs / no pages) ✅ DONE
- Error handling (failed export, failed OCR, permission denied) ⏳
- Performance: avoid keeping huge images in memory (use downsampling) ⏳
- Basic accessibility: button sizes, labels ⏳

**Current Status:** Empty states implemented. Permissions, error handling, and performance optimizations pending.

TRACK B STATUS:
- ✅ B1: Photo import - COMPLETE
- ✅ B2: Document scanner - COMPLETE  
- ✅ B3: Pages management - COMPLETE
- ✅ B4: OCR - COMPLETE
- ⚠️ B5: Export - NEEDS TESTING
- ✅ B6: Persistence - COMPLETE
- 🔄 B7: Polish - IN PROGRESS
- ✅ B8: Tag Management - COMPLETE

TRACK B DONE when:
- Full scan pipeline works with real data. ✅
- Exports and persistence are reliable. ⚠️ (Export needs testing)
- App feels production-ready. 🔄 (Polish in progress)

---

## Dependency Injection (how to swap stubs to real)
Create a simple AppEnvironment:
- holds implementations of each protocol
- Track A uses stubs
- Track B swaps to real implementations step-by-step

Rule:
- Views depend on stores; stores depend on protocols.
- No View should directly use AVFoundation/Vision/PDFKit/FileManager.
- Exception: VNDocumentCameraViewController can be used directly in views (it's a UIKit view controller presented modally).

---

## Cursor Implementation Rules (per step)
For each step:
1) Search codebase for existing patterns/components.
2) Implement minimal, compiling version.
3) Output full file contents for files you change/create.
4) Do not implement future steps early.
5) Never introduce new colors/fonts; use NB theme/components.
6) Build one feature at a time, test, then move to next.
7) Keep a todo list checking off each implemented feature to track progress.