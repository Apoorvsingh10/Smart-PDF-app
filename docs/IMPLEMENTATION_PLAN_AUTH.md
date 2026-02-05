# PdfPilot Authentication Implementation Plan (Firebase)

## 1. Firebase Console Setup (Action Required by User)
Before code integration, you must set up the project in the Firebase Console:

1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add project** and name it "PdfPilot".
3.  Once created, click the **Android** icon to add an app.
    *   **Package name**: `com.pdfpilot.app` (Must match `AndroidManifest.xml`).
    *   **Debug signing certificate SHA-1**: Run `keytool -list -v -keystore <your_debug_keystore>` (Optional for now, but required for Google Sign-In).
4.  Download **google-services.json**.
5.  Move this file to your project folder: `android/google-services.json`.
6.  In Firebase Console, go to **Build > Authentication**.
7.  Click **Get Started**.
8.  Enable **Google** (requires SHA-1) and **Facebook** (requires App ID/Secret from Meta Developers).

## 2. Download Firebase C++ SDK (Action Required by User)
1.  Download the **Firebase C++ SDK** (Version 11.x or later) from [Google](https://firebase.google.com/download/cpp).
2.  Extract it to a folder, e.g., `C:/Firebase_CPP_SDK`.
3.  (Ideally, place it inside your project or a known library path, e.g., `libs/firebase_cpp_sdk`).

## 3. Project Configuration Updates

### A. CMakeLists.txt
Link the Firebase libraries (`app`, `auth`) to the project.

```cmake
# Add near the top
set(FIREBASE_CPP_SDK_DIR "path/to/firebase_cpp_sdk") # Update this path!

# Include directories
include_directories(${FIREBASE_CPP_SDK_DIR}/include)

# Link libraries (Android)
add_library(firebase_app STATIC IMPORTED)
set_property(TARGET firebase_app PROPERTY IMPORTED_LOCATION ${FIREBASE_CPP_SDK_DIR}/libs/android/arm64-v8a/c++/libfirebase_app.a)

add_library(firebase_auth STATIC IMPORTED)
set_property(TARGET firebase_auth PROPERTY IMPORTED_LOCATION ${FIREBASE_CPP_SDK_DIR}/libs/android/arm64-v8a/c++/libfirebase_auth.a)

target_link_libraries(appPDF_ToolKit PRIVATE firebase_app firebase_auth)
```
*Note: You may need to handle different ABIs (x86, arm64, etc.) or just target arm64 for physical devices.*

### B. Android Build Configuration
We need to apply the Google Services Gradle plugin.

1.  Create `android/build.gradle` (Custom Gradle file).
2.  Add the dependencies:
    ```gradle
    dependencies {
        implementation 'com.google.firebase:firebase-auth:22.3.0'
        implementation 'com.google.android.gms:play-services-auth:20.7.0'
    }
    apply plugin: 'com.google.gms.google-services'
    ```
3.  Modify `AndroidManifest.xml` (Qt handles most permissions, but ensure Internet is there).

## 4. C++ Architecture

### Create `AuthManager` Class
A singleton class to manage authentication state and operations.

*   **File**: `src/utils/AuthManager.h` / `.cpp`
*   **Methods**:
    *   `loginWithGoogle()`
    *   `loginWithFacebook()`
    *   `signOut()`
    *   `getCurrentUser()`
*   **Signals**:
    *   `userChanged(User)`
    *   `errorOccurred(String)`
*   **Implementation**:
    *   Initialize `firebase::App`.
    *   Initialize `firebase::auth::Auth`.
    *   Use `QJniObject` (Qt Android Extras) to handle the native Google Sign-In intent flows if the C++ SDK helper needs it, though 11.0+ often handles it internally or requires simple explicit activity association.

## 5. UI Implementation

### A. LoginScreen.qml
A beautiful login screen matching your app's premium aesthetic.
*   **Logo** at top.
*   **"Sign in with Google"** button (White/Google Blue).
*   **"Sign in with Facebook"** button (Facebook Blue).
*   **"Skip / Continue as Guest"** option (if permitted).

### B. Navigation Update (Main.qml)
*   Check `AuthManager.isAuthenticated` on startup.
*   If false, show `LoginScreen`.
*   If true, show `HomeScreen`.

## 6. Next Steps
1.  **User Action**: Get `google-services.json` and the SDK.
2.  **Dev Action**: I will generate the `AuthManager` code and `LoginScreen.qml`.
3.  **Dev Action**: I will update `CMakeLists.txt` (commented out until SDK path is known).
