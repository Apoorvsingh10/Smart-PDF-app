#include "Settings.h"
#include <QQmlEngine>

Settings* Settings::s_instance = nullptr;

Settings::Settings(QObject *parent) : QObject(parent),
    m_settings("PDFToolKit", "PDF_ToolKit")
{
}

Settings* Settings::instance()
{
    if (!s_instance) {
        s_instance = new Settings();
    }
    return s_instance;
}

Settings* Settings::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    Settings *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

QString Settings::theme() const
{
    return m_settings.value("theme", "system").toString();
}

void Settings::setTheme(const QString &theme)
{
    if (this->theme() == theme) return;
    m_settings.setValue("theme", theme);
    emit themeChanged();
}

bool Settings::isPro() const
{
    return m_settings.value("isPro", false).toBool();
}

void Settings::setIsPro(bool value)
{
    if (isPro() == value) return;
    m_settings.setValue("isPro", value);
    emit isProChanged();
}

QString Settings::lastDirectory() const
{
    return m_settings.value("lastDirectory", "").toString();
}

void Settings::setLastDirectory(const QString &dir)
{
    if (lastDirectory() == dir) return;
    m_settings.setValue("lastDirectory", dir);
    emit lastDirectoryChanged();
}

int Settings::compressionLevel() const
{
    return m_settings.value("compressionLevel", 1).toInt();
}

void Settings::setCompressionLevel(int level)
{
    if (compressionLevel() == level) return;
    m_settings.setValue("compressionLevel", level);
    emit compressionLevelChanged();
}
