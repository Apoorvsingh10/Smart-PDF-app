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

    // AI Settings
    Q_PROPERTY(QString aiApiKey READ aiApiKey WRITE setAiApiKey NOTIFY aiApiKeyChanged)
    Q_PROPERTY(int aiUsageCount READ aiUsageCount WRITE setAiUsageCount NOTIFY aiUsageCountChanged)
    Q_PROPERTY(bool aiPurchased READ aiPurchased WRITE setAiPurchased NOTIFY aiPurchasedChanged)

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

    // AI Settings
    QString aiApiKey() const;
    void setAiApiKey(const QString &key);

    int aiUsageCount() const;
    void setAiUsageCount(int count);

    bool aiPurchased() const;
    void setAiPurchased(bool purchased);

signals:
    void themeChanged();
    void isProChanged();
    void lastDirectoryChanged();
    void compressionLevelChanged();
    void aiApiKeyChanged();
    void aiUsageCountChanged();
    void aiPurchasedChanged();

private:
    explicit Settings(QObject *parent = nullptr);
    static Settings *s_instance;
    QSettings m_settings;
};

#endif // SETTINGS_H
