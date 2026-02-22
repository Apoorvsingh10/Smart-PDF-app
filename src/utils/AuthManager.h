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
    Q_PROPERTY(QString userId READ userId NOTIFY userChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY userChanged)
    Q_PROPERTY(QString userEmail READ userEmail NOTIFY userChanged)
    Q_PROPERTY(QString userPhotoUrl READ userPhotoUrl NOTIFY userChanged)
    Q_PROPERTY(QString idToken READ idToken NOTIFY idTokenChanged)

public:
    static AuthManager* instance();
    static AuthManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isAuthenticated() const;
    QString userId() const;
    QString userName() const;
    QString userEmail() const;
    QString userPhotoUrl() const;
    QString idToken() const;

    Q_INVOKABLE void refreshIdToken();

    Q_INVOKABLE void loginWithGoogle();

    Q_INVOKABLE void loginAnonymously(); // Guest mode
    Q_INVOKABLE void signOut();

signals:
    void userChanged();
    void idTokenChanged();
    void authError(const QString &message);
    void authSuccess(const QString &message);

public slots:
    void handleAuthSuccess(const QString &userId, const QString &userName, const QString &userEmail, const QString &photoUrl);
    void handleAuthError(const QString &errorMessage);
    void handleIdToken(const QString &token);

private:
    explicit AuthManager(QObject *parent = nullptr);
    static AuthManager *s_instance;

    bool m_isAuthenticated;
    QString m_userId;
    QString m_userName;
    QString m_userEmail;
    QString m_userPhotoUrl;
    QString m_idToken;
    bool m_tokenRefreshInProgress = false;
};

#endif // AUTHMANAGER_H
