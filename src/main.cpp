#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QUrl>

// Include to ensure JNI functions are linked
#include "utils/FileReceiver.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName("PDFToolKit");
    QCoreApplication::setApplicationName("PDF ToolKit");
    QCoreApplication::setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Material");

    // Types are auto-registered via QML_ELEMENT in headers
    // through qt_add_qml_module in CMakeLists.txt

    QQmlApplicationEngine engine;

    // Add import paths for the QML module
    engine.addImportPath("qrc:/");
    engine.addImportPath("qrc:/qt/qml");

    const QUrl url(QStringLiteral("qrc:/PDF_ToolKit/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
