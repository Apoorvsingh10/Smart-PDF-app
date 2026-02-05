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
        qml/components/FilePickerButton.qml
        qml/components/ProgressOverlay.qml
        qml/components/ToastNotification.qml
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
    RESOURCE_PREFIX "/"
)

target_link_libraries(appPDF_ToolKit PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Concurrent
    Qt6::Svg
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
    set_target_properties(appPDF_ToolKit PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_TARGET_SDK_VERSION 34
        QT_ANDROID_MIN_SDK_VERSION 24
    )
endif()

install(TARGETS appPDF_ToolKit
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
