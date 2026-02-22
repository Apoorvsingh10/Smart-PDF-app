#ifndef PDFTEXTEXTRACTOR_H
#define PDFTEXTEXTRACTOR_H

#include <QObject>
#include <QUrl>
#include <QtQml>

class PDFTextExtractor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isImageBased READ isImageBased NOTIFY extractionComplete)
    Q_PROPERTY(QString extractedText READ extractedText NOTIFY extractionComplete)
    Q_PROPERTY(QStringList pageImages READ pageImages NOTIFY extractionComplete)
    Q_PROPERTY(int pageCount READ pageCount NOTIFY extractionComplete)
    Q_PROPERTY(bool isExtracting READ isExtracting NOTIFY extractingChanged)

public:
    static PDFTextExtractor* instance();
    static PDFTextExtractor* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isImageBased() const;
    QString extractedText() const;
    QStringList pageImages() const;
    int pageCount() const;
    bool isExtracting() const;

    Q_INVOKABLE void extract(const QString &filePath);
    Q_INVOKABLE void extractFromUrl(const QUrl &fileUrl);
    Q_INVOKABLE QString extractText(const QString &filePath);
    Q_INVOKABLE QString extractTextFromUrl(const QUrl &fileUrl);
    Q_INVOKABLE int getPageCount(const QString &filePath);

signals:
    void extractionComplete();
    void extractingChanged();
    void errorOccurred(const QString &error);

private:
    explicit PDFTextExtractor(QObject *parent = nullptr);
    static PDFTextExtractor *s_instance;

    QString extractWithQPdf(const QString &path);
    QStringList extractPagesAsImages(const QString &path);
    QString urlToLocalPath(const QUrl &url);

    bool m_isImageBased;
    QString m_extractedText;
    QStringList m_pageImages;
    int m_pageCount;
    bool m_isExtracting;

    static constexpr int MIN_TEXT_LENGTH = 50;
    static constexpr int MAX_IMAGE_PAGES = 10;
};

#endif // PDFTEXTEXTRACTOR_H
