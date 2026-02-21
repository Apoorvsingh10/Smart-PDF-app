#ifndef AUTHMANAGER_H
#define AUTHMANAGER_H

#include <QObject>
#include <QtQml>

class AuthManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY userChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY userChanged)
    Q_PROPERTY(QString userEmail READ userEmail NOTIFY userChanged)
    Q_PROPERTY(QString userPhotoUrl READ userPhotoUrl NOTIFY userChanged)

public:
    static AuthManager* instance();
    static AuthManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isAuthenticated() const;
    QString userName() const;
    QString userEmail() const;
    QString userPhotoUrl() const;

    Q_INVOKABLE void loginWithGoogle();

    Q_INVOKABLE void loginAnonymously(); // Guest mode
    Q_INVOKABLE void signOut();

signals:
    void userChanged();
    void authError(const QString &message);
    void authSuccess(const QString &message);

public slots:
    void handleAuthSuccess(const QString &userId, const QString &userName, const QString &userEmail, const QString &photoUrl);
    void handleAuthError(const QString &errorMessage);

private:
    explicit AuthManager(QObject *parent = nullptr);
    static AuthManager *s_instance;

    bool m_isAuthenticated;
    QString m_userName;
    QString m_userEmail;
    QString m_userPhotoUrl;
};

#endif // AUTHMANAGER_H
