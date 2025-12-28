# MonkScan App Store Compliance Plan
## December 2025 - Apple App Store Review Guidelines

---

## 📋 Executive Summary

Based on the latest Apple App Store Review Guidelines (2025) and technical requirements, this document outlines all necessary changes to ensure MonkScan's approval for the App Store.

**Status**: MVP Complete - Compliance Review Required  
**Risk Level**: Medium - Several critical issues need addressing before submission

---

## 🚨 CRITICAL ISSUES (Must Fix Before Submission)

### 1. **Invalid iOS Deployment Target** ⚠️ CRITICAL
**Issue**: `IPHONEOS_DEPLOYMENT_TARGET = 26.0` is invalid
- Current: iOS 26.0 (doesn't exist - likely typo)
- Required: iOS 15.0 minimum (Apple requirement)
- Recommended: iOS 17.0+ (for modern features & broader compatibility)

**Why it matters**: App won't pass validation or build correctly for distribution.

**Fix Location**: `MonkScan.xcodeproj/project.pbxproj` lines 181, 239, 266, 301

**Fix**:
```
Change: IPHONEOS_DEPLOYMENT_TARGET = 26.0;
To:     IPHONEOS_DEPLOYMENT_TARGET = 17.0;
```

---

### 2. **Force-Try Crash Risk** ⚠️ CRITICAL
**Issue**: Using `try!` in app initialization causes instant crash if file system is unavailable
- Found in: MonkScanApp.swift (line 10)
- Found in: 5 Preview providers across the codebase
- Risk: App crashes immediately on launch if Documents directory is inaccessible

**Why it matters**: Apple rejects apps that crash on launch. This is a guaranteed rejection.

**Fix**: Replace with proper error handling:
```swift
// CURRENT (BAD):
let documentStore = try! FileDocumentStore()

// REQUIRED (GOOD):
let documentStore: FileDocumentStore
do {
    documentStore = try FileDocumentStore()
} catch {
    // Show error UI or use fallback
    fatalError("Failed to initialize document store: \(error)")
    // Note: In production, show an alert instead of fatalError
}
```

**Locations to fix**:
- MonkScanApp.swift:10
- LibraryView.swift:207
- DocumentDetailView.swift:389
- EditMetadataView.swift:179
- SavedPageEditView.swift:341
- ExportView.swift:594

---

### 3. **Missing Photo Library Permission Description** ⚠️ CRITICAL
**Issue**: Missing `NSPhotoLibraryUsageDescription` (read access)
- Currently have: `NSPhotoLibraryAddUsageDescription` (write/add only)
- Missing: `NSPhotoLibraryUsageDescription` (read/import)

**Why it matters**: Required for PhotosPicker to work. App Store requires this before allowing photo access.

**Fix Location**: `MonkScan.xcodeproj/project.pbxproj`

**Add**:
```
INFOPLIST_KEY_NSPhotoLibraryUsageDescription = "MonkScan needs access to your photo library to import and scan documents from your photos.";
```

---

## 🔴 HIGH PRIORITY ISSUES

### 4. **Debug Print Statements** ⚠️ HIGH
**Issue**: Using `print()` for error logging in production code
- Found in: ExportService.swift (lines 71, 109, 140)

**Why it matters**: Not a rejection issue, but unprofessional. Apple recommends proper logging (os_log/Logger).

**Fix**: Replace with OSLog:
```swift
import OSLog

private let logger = Logger(subsystem: "com.thomas.MonkScan", category: "ExportService")

// Replace:
print("Failed to create PDF: \(error)")
// With:
logger.error("Failed to create PDF: \(error.localizedDescription)")
```

---

### 5. **App Store Rating Implementation Missing** ⚠️ HIGH
**Issue**: "Rate MonkScan" button in Settings does nothing
- Location: SettingsView.swift:62-73

**Why it matters**: Non-functional buttons can cause rejection (4.2 - Minimum Functionality).

**Fix**: Implement StoreKit rating prompt:
```swift
import StoreKit

Button {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
    }
} label: {
    HStack {
        Text("Rate MonkScan")
            .font(NBType.body)
            .foregroundStyle(NBColors.ink)
        Spacer()
        Image(systemName: "star")
            .foregroundStyle(NBColors.yellow)
    }
}
```

---

## 🟡 MEDIUM PRIORITY ISSUES

### 6. **Bundle Identifier Best Practice** ⚠️ MEDIUM
**Issue**: Bundle ID `com.thomas.MonkScan` uses first name
- Current: `com.thomas.MonkScan`
- Recommended: `com.yourcompany.MonkScan` or `com.yourdomain.MonkScan`

**Why it matters**: Better for professionalism and if you transfer ownership later.

**Fix**: Update in project.pbxproj if desired (optional but recommended).

---

### 7. **Version Number Format** ⚠️ MEDIUM
**Issue**: Version "1.0.0" shown in UI but "1.0" in build settings
- UI (SettingsView.swift:55): Shows "1.0.0"
- Build settings: `MARKETING_VERSION = 1.0`

**Why it matters**: Inconsistency can confuse users and Apple review team.

**Fix**: Make consistent:
- Option A: Change SettingsView to show `MARKETING_VERSION` dynamically
- Option B: Update MARKETING_VERSION to "1.0.0"

**Dynamic version code**:
```swift
Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
```

---

### 8. **Encryption Export Compliance** ⚠️ MEDIUM
**Issue**: Missing export compliance declaration
- Required if app uses encryption (HTTPS, etc.)

**Why it matters**: App Store Connect will ask during submission. Pre-declaring saves time.

**Fix**: Add to project.pbxproj:
```
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
```

(Set to NO if you only use standard iOS encryption. Set to YES if you implement custom encryption.)

---

## 🟢 LOW PRIORITY / OPTIONAL

### 9. **Support URL Missing**
**Issue**: No support URL or privacy policy URL configured

**Why it matters**: Apple strongly recommends (sometimes requires) these for user trust.

**Recommendation**: Create simple pages:
- Privacy Policy: Explain data usage (all local, no cloud, no tracking)
- Support: Contact email or simple FAQ

**Add to project**:
```
INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
```

---

### 10. **App Icon Alpha Channel**
**Issue**: Need to verify app icon has no transparency

**Why it matters**: App Store requires opaque icons (no alpha channel).

**Verification**: Open `monk-logo-final.png` in Preview/Photoshop and check:
- Must be 1024x1024
- Must be opaque (no transparency)
- Must be RGB (not CMYK)

---

### 11. **Launch Screen**
**Status**: Using `INFOPLIST_KEY_UILaunchScreen_Generation = YES` (SwiftUI default)

**Recommendation**: Good for MVP, but consider custom launch screen for branding.

---

### 12. **Accessibility Improvements**
**Status**: Basic accessibility implemented (✅ from MVP_FEATURES.md)

**Recommendation**: Test with VoiceOver before submission to ensure smooth experience.

---

## 📱 APP STORE SUBMISSION REQUIREMENTS

### Metadata Requirements (Prepare before submission):
1. **App Name**: "MonkScan" (check availability in App Store Connect)
2. **Subtitle**: Max 30 characters (e.g., "Document Scanner & OCR")
3. **Description**: 
   - What: Offline document scanner
   - Why: Simple, fast, local storage
   - How: Scan, crop, enhance, OCR, export as PDF/JPG/Text
4. **Keywords**: document,scanner,pdf,ocr,scan,camera,export,offline
5. **Screenshots**: Required for:
   - 6.7" iPhone (iPhone 15 Pro Max)
   - 6.5" iPhone (iPhone 14 Plus)
   - 5.5" iPhone (optional, older devices)
   - 12.9" iPad Pro
   - Need 3-10 screenshots showing key features
6. **App Preview Video**: Optional but recommended (15-30 sec demo)
7. **Categories**: 
   - Primary: Productivity
   - Secondary: Business
8. **Age Rating**: 4+ (no objectionable content)
9. **Privacy Policy URL**: Required if collecting any data
   - Your app: All local storage, no servers
   - Recommendation: Simple one-pager stating "no data collection"

### App Store Connect Configuration:
1. **Copyright**: "© 2025 [Your Name/Company]"
2. **Contact Information**: Support email required
3. **Review Notes**: Explain app requires camera access for core functionality
4. **Export Compliance**: Declare encryption usage
5. **Content Rights**: Confirm you own all content/assets

---

## 🎯 PRIORITY CHECKLIST (Fix Order)

### Must Fix Before Any Testing:
- [ ] 1. Fix iOS deployment target (26.0 → 17.0)
- [ ] 2. Replace all `try!` with proper error handling
- [ ] 3. Add missing NSPhotoLibraryUsageDescription

### Must Fix Before Submission:
- [ ] 4. Replace print() with proper logging
- [ ] 5. Implement "Rate MonkScan" button functionality
- [ ] 6. Add encryption export compliance flag
- [ ] 7. Verify app icon format (1024x1024, opaque, RGB)

### Should Fix Before Submission:
- [ ] 8. Make version numbers consistent (UI vs build settings)
- [ ] 9. Consider updating bundle identifier
- [ ] 10. Prepare privacy policy (simple: "no data collection, all local")

### Nice to Have:
- [ ] 11. Test thoroughly with VoiceOver
- [ ] 12. Create support email/webpage
- [ ] 13. Consider custom launch screen

---

## 📚 APPLE GUIDELINES REFERENCES

### Key Guidelines to Review:
1. **2.1 - App Completeness**: App must be fully functional (you're good ✅)
2. **2.3 - Accurate Metadata**: Descriptions match functionality ✅
3. **2.4 - Hardware Compatibility**: Must work on all devices (check iPad) ⚠️
4. **3.1 - Payments**: Not applicable (no IAP) ✅
5. **4.2 - Minimum Functionality**: All buttons must work ⚠️ (Rate button)
6. **5.1 - Privacy**: Data collection must be disclosed ✅ (none collected)
7. **5.1.1 - Data Collection**: Permission descriptions must be clear ⚠️ (add photo read)

### Technical Requirements:
- iOS SDK: Latest stable (currently iOS 18.2 SDK)
- Xcode: Latest stable (currently Xcode 16.2)
- Swift: 5.0+ ✅
- Architectures: arm64 (iPhone 5s and later) ✅
- iPadOS: Must support if TARGETED_DEVICE_FAMILY includes iPad ✅ (1,2)

---

## 🛠️ TESTING RECOMMENDATIONS

### Before Submission:
1. **Clean Build Test**:
   ```
   1. Product > Clean Build Folder
   2. Delete derived data
   3. Archive for distribution
   4. Check for warnings
   ```

2. **Device Testing**:
   - Test on physical iPhone (not just simulator)
   - Test camera scanning (simulator doesn't support this)
   - Test on iPad if claiming iPad support
   - Test on oldest supported iOS version (17.0)

3. **Functionality Test**:
   - Camera permission flow
   - Photo import permission flow
   - Full scan → edit → export → share workflow
   - Library: save, load, delete, search
   - Settings: all toggles work and persist
   - Export: all formats (PDF, JPG, Text)
   - OCR: verify text extraction works

4. **Edge Cases**:
   - No camera access (should show alert)
   - No photo access (should show alert)
   - Empty library (should show empty state)
   - Very large document (50+ pages)
   - Low storage (app handles gracefully)
   - Background/foreground transitions

5. **Memory & Performance**:
   - Profile with Instruments (check for leaks)
   - Test with multiple large documents
   - Verify downsampling is working (memory stays low)

---

## 📝 SUMMARY OF CODE CHANGES NEEDED

### Files to Modify:
1. **MonkScan.xcodeproj/project.pbxproj** (4 changes)
   - Fix deployment target: 26.0 → 17.0 (4 occurrences)
   - Add NSPhotoLibraryUsageDescription
   - Add ITSAppUsesNonExemptEncryption

2. **MonkScanApp.swift** (1 change)
   - Replace try! with proper error handling

3. **Preview Providers** (5 changes)
   - LibraryView.swift
   - DocumentDetailView.swift
   - EditMetadataView.swift
   - SavedPageEditView.swift
   - ExportView.swift
   - Replace try! with try?/if-let for previews

4. **ExportService.swift** (3 changes)
   - Replace print() with OSLog

5. **SettingsView.swift** (1 change)
   - Implement StoreKit rating prompt

6. **Optional: Create Privacy Policy** (1 new file/webpage)
   - Simple markdown/HTML page
   - Statement: "MonkScan stores all data locally on your device. We do not collect, transmit, or store any user data on external servers."

---

## 🎉 WHAT'S ALREADY COMPLIANT

### Good News - You've Already Done These Right:
- ✅ Camera permission description is clear and accurate
- ✅ App has real, substantial functionality (not a wrapper)
- ✅ No third-party login required (offline-first)
- ✅ No ads, no IAP, no subscriptions
- ✅ No data collection or external servers
- ✅ Clean UI following Apple Human Interface Guidelines
- ✅ Error handling for permissions (camera/photos)
- ✅ Empty states implemented
- ✅ Performance optimizations (downsampling)
- ✅ Basic accessibility implemented
- ✅ No use of private APIs
- ✅ No third-party dependencies (all native frameworks)
- ✅ Proper file system usage (Documents directory)
- ✅ Support for both iPhone and iPad
- ✅ Landscape and portrait orientations

---

## 🚀 RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Critical Fixes (1-2 hours)
1. Fix deployment target in Xcode project settings
2. Add missing photo library permission
3. Replace try! in MonkScanApp.swift with proper error handling
4. Replace try! in preview providers (can use try? there)

### Phase 2: High Priority (2-3 hours)
5. Add OSLog throughout ExportService
6. Implement StoreKit rating in Settings
7. Add encryption compliance flag
8. Test full app on physical device

### Phase 3: Polish (1-2 hours)
9. Create simple privacy policy webpage
10. Make version numbers consistent
11. Final testing with VoiceOver
12. Prepare App Store screenshots

### Phase 4: Submission (1 hour)
13. Archive build in Xcode
14. Upload to App Store Connect
15. Fill out metadata
16. Submit for review

**Total Estimated Time: 6-8 hours**

---

## 📞 SUPPORT DURING REVIEW

If Apple review team has questions:
- Have camera/photo permission explanations ready
- Emphasize: offline-first, privacy-focused, no data collection
- Provide test account if requested (N/A for this app)
- Respond quickly to any feedback (within 24-48 hours)

---

## ✅ FINAL PRE-SUBMISSION CHECKLIST

Before clicking "Submit for Review":
- [ ] All critical issues fixed
- [ ] App builds without warnings
- [ ] Tested on physical iPhone
- [ ] Tested on physical iPad (if claiming support)
- [ ] All features work as described
- [ ] Screenshots uploaded (3-10 per device size)
- [ ] Description/keywords added
- [ ] Privacy policy URL added (if applicable)
- [ ] Support URL/email added
- [ ] Export compliance answered
- [ ] Age rating completed
- [ ] App icon uploaded (1024x1024)
- [ ] Build uploaded and selected
- [ ] Review notes added (explain camera requirement)
- [ ] Pricing set (free or paid)

---

## 📚 ADDITIONAL RESOURCES

### Official Apple Documentation:
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/

### Useful Tools:
- TestFlight: Beta testing before public release
- App Store Connect API: Automate metadata/screenshots
- Xcode Organizer: Crash logs and analytics post-launch

---

**Last Updated**: December 28, 2025  
**MonkScan Version**: 1.0 (MVP)  
**Prepared By**: App Store Compliance Review

