#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QtQml>

class Settings : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(bool isPro READ isPro WRITE setIsPro NOTIFY isProChanged)
    Q_PROPERTY(QString lastDirectory READ lastDirectory WRITE setLastDirectory NOTIFY lastDirectoryChanged)
    Q_PROPERTY(int compressionLevel READ compressionLevel WRITE setCompressionLevel NOTIFY compressionLevelChanged)

public:
    static Settings* instance();
    static Settings* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QString theme() const;
    void setTheme(const QString &theme);

    bool isPro() const;
    void setIsPro(bool value);

    QString lastDirectory() const;
    void setLastDirectory(const QString &dir);

    int compressionLevel() const;
    void setCompressionLevel(int level);

signals:
    void themeChanged();
    void isProChanged();
    void lastDirectoryChanged();
    void compressionLevelChanged();

private:
    explicit Settings(QObject *parent = nullptr);
    static Settings *s_instance;
    QSettings m_settings;
};

#endif // SETTINGS_H
