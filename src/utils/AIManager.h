#ifndef AIMANAGER_H
#define AIMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QtQml>

class AIManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isLoading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString currentPdfText READ currentPdfText WRITE setCurrentPdfText NOTIFY pdfTextChanged)
    Q_PROPERTY(QString currentResponse READ currentResponse NOTIFY responseChanged)
    Q_PROPERTY(bool isImageBased READ isImageBased WRITE setIsImageBased NOTIFY imageBasedChanged)
    Q_PROPERTY(QStringList currentPageImages READ currentPageImages WRITE setCurrentPageImages NOTIFY pageImagesChanged)

public:
    static AIManager* instance();
    static AIManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isLoading() const;
    QString currentPdfText() const;
    void setCurrentPdfText(const QString &text);
    QString currentResponse() const;
    bool isImageBased() const;
    void setIsImageBased(bool imageBased);
    QStringList currentPageImages() const;
    void setCurrentPageImages(const QStringList &images);

    Q_INVOKABLE void summarizePdf();
    Q_INVOKABLE void askQuestion(const QString &question);
    Q_INVOKABLE void cancelRequest();
    Q_INVOKABLE void clearResponse();

signals:
    void loadingChanged();
    void pdfTextChanged();
    void responseChanged();
    void imageBasedChanged();
    void pageImagesChanged();
    void responseReady(const QString &response);
    void errorOccurred(const QString &error);
    void accessDenied();
    void limitReached(const QString &resetDate);

private:
    explicit AIManager(QObject *parent = nullptr);
    static AIManager *s_instance;

    void sendTextRequest(const QString &systemPrompt, const QString &userMessage);
    void sendImageRequest(const QString &systemPrompt, const QString &userMessage);
    void handleResponse(QNetworkReply *reply);
    QString truncateText(const QString &text, int maxChars = 50000);
    bool checkAccessAndUsage();

    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    QString m_currentPdfText;
    QString m_currentResponse;
    bool m_isLoading;
    bool m_isImageBased;
    QStringList m_currentPageImages;

    static constexpr int MAX_TEXT_LENGTH = 50000;
    static constexpr int MAX_IMAGE_PAGES = 10;
};

#endif // AIMANAGER_H
