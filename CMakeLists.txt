cmake_minimum_required(VERSION 3.21)

project(PDF_ToolKit VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Android STL configuration
if(ANDROID)
    set(ANDROID_STL c++_shared)
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Concurrent
    Svg
    Network
)

# Qt PDF is now available (installed via Maintenance Tool)
find_package(Qt6 6.5 COMPONENTS Pdf PdfQuick)

if(Qt6Pdf_FOUND)
    add_compile_definitions(HAS_QT_PDF)
endif()

qt_standard_project_setup(REQUIRES 6.5)

# Main entry point only - QML types are added via qt_add_qml_module
qt_add_executable(appPDF_ToolKit
    src/main.cpp
)

# Add include directories so generated type registration can find headers
target_include_directories(appPDF_ToolKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src/viewmodels
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utils
)

# Set QML type names (flatten directory structure for type registration)
# Set QML type names (flatten directory structure for type registration)
set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(appPDF_ToolKit
    URI PDF_ToolKit
    VERSION 1.0
    SOURCES
        src/core/PDFEngine.h src/core/PDFEngine.cpp
        src/core/PDFDocument.h src/core/PDFDocument.cpp
        src/viewmodels/MainViewModel.h src/viewmodels/MainViewModel.cpp
        src/utils/Settings.h src/utils/Settings.cpp
        src/utils/FileUtils.h src/utils/FileUtils.cpp
        src/utils/FolderManager.h src/utils/FolderManager.cpp
        src/utils/RecentActivityModel.h src/utils/RecentActivityModel.cpp
        src/utils/ShareUtils.h src/utils/ShareUtils.cpp
        src/utils/AuthManager.h src/utils/AuthManager.cpp
        src/utils/AIManager.h src/utils/AIManager.cpp
        src/utils/PDFTextExtractor.h src/utils/PDFTextExtractor.cpp
        src/utils/SubscriptionManager.h src/utils/SubscriptionManager.cpp
        src/utils/PaymentManager.h src/utils/PaymentManager.cpp
        src/utils/FileReceiver.h src/utils/FileReceiver.cpp
    QML_FILES
        qml/Main.qml
        qml/theme/Theme.qml
        qml/screens/HomeScreen.qml
        qml/screens/LoginScreen.qml
        qml/screens/ViewerScreen.qml
        qml/screens/MergeScreen.qml
        qml/screens/SplitScreen.qml
        qml/screens/CompressScreen.qml
        qml/screens/SettingsScreen.qml
        qml/screens/FoldersScreen.qml
        qml/screens/AIScreen.qml
        qml/screens/PaywallScreen.qml
        qml/components/FilePickerButton.qml
        qml/components/PurchaseDialog.qml
        qml/components/ProgressOverlay.qml
        qml/components/ToastNotification.qml
        qml/components/UserProfileButton.qml
    RESOURCES
        resources/icons/home.svg
        resources/icons/viewer.svg
        resources/icons/tools.svg
        resources/icons/settings.svg
        resources/icons/merge.svg
        resources/icons/split.svg
        resources/icons/compress.svg
        resources/icons/add.svg
        resources/icons/delete.svg
        resources/icons/back.svg
        resources/icons/pdf.svg
        resources/icons/save.svg
        resources/icons/folder.svg
        resources/icons/share.svg
        resources/icons/default_user.svg
        resources/icons/default_user_dark.svg
        resources/icons/arrow_down.svg
        resources/icons/logout.svg
        resources/icons/ai.svg
        resources/icons/fullscreen.svg
        resources/icons/fullscreen_exit.svg
        resources/icons/copy.svg
    RESOURCE_PREFIX "/"
)

# Gemini API key configuration (keeps it out of source control)
# Option 1: From api_key.cmake file (recommended - add to .gitignore)
if(EXISTS "${CMAKE_SOURCE_DIR}/api_key.cmake")
    include("${CMAKE_SOURCE_DIR}/api_key.cmake")
    if(GEMINI_API_KEY AND NOT GEMINI_API_KEY STREQUAL "YOUR_API_KEY_HERE")
        target_compile_definitions(appPDF_ToolKit PRIVATE
            GEMINI_API_KEY="${GEMINI_API_KEY}"
        )
        message(STATUS "Gemini API key configured from api_key.cmake")
    else()
        message(WARNING "api_key.cmake found but GEMINI_API_KEY not set properly")
    endif()
# Option 2: From environment variable
elseif(DEFINED ENV{GEMINI_API_KEY})
    target_compile_definitions(appPDF_ToolKit PRIVATE
        GEMINI_API_KEY="$ENV{GEMINI_API_KEY}"
    )
    message(STATUS "Gemini API key configured from environment variable")
else()
    message(WARNING "GEMINI_API_KEY not set - create api_key.cmake or set environment variable")
endif()

target_link_libraries(appPDF_ToolKit PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Concurrent
    Qt6::Svg
    Qt6::Network
)

# Link PDF modules only if available
if(Qt6Pdf_FOUND)
    target_link_libraries(appPDF_ToolKit PRIVATE
        Qt6::Pdf
        Qt6::PdfQuick
    )
endif()

# Android configuration
if(ANDROID)
    # Include the official Android OpenSSL cmake helper
    # This properly sets up OpenSSL::SSL and OpenSSL::Crypto targets
    include("$ENV{LOCALAPPDATA}/Android/Sdk/android_openssl/android_openssl.cmake")

    # Use the helper function to add OpenSSL libraries to the target
    # This automatically:
    # - Links OpenSSL::SSL and OpenSSL::Crypto
    # - Adds the .so files to QT_ANDROID_EXTRA_LIBS so they're bundled in the APK
    add_android_openssl_libraries(appPDF_ToolKit)

    set_target_properties(appPDF_ToolKit PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_TARGET_SDK_VERSION 34
        QT_ANDROID_MIN_SDK_VERSION 24
        QT_ANDROID_ACTIVITY_NAME "io.smartpdf.app.SmartPdfActivity"
    )
endif()

install(TARGETS appPDF_ToolKit
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
