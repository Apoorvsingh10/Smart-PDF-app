#ifndef PDFDOCUMENT_H
#define PDFDOCUMENT_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml>

#ifdef HAS_QT_PDF
#include <QPdfDocument>
#endif

class PDFDocument : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
    Q_PROPERTY(int pageCount READ pageCount NOTIFY pageCountChanged)
    Q_PROPERTY(bool isLoaded READ isLoaded NOTIFY isLoadedChanged)
    Q_PROPERTY(qint64 fileSize READ fileSize NOTIFY fileSizeChanged)
    Q_PROPERTY(bool hasPdfViewer READ hasPdfViewer CONSTANT)
#ifdef HAS_QT_PDF
    Q_PROPERTY(QPdfDocument* document READ document CONSTANT)
#endif

public:
    explicit PDFDocument(QObject *parent = nullptr);
    ~PDFDocument();

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);

    QString filePath() const { return m_filePath; }
    QString fileName() const { return m_fileName; }
    int pageCount() const { return m_pageCount; }
    bool isLoaded() const { return m_isLoaded; }
    qint64 fileSize() const { return m_fileSize; }

#ifdef HAS_QT_PDF
    QPdfDocument* document() const { return m_document; }
    bool hasPdfViewer() const { return true; }
#else
    bool hasPdfViewer() const { return false; }
#endif

    Q_INVOKABLE void close();
    Q_INVOKABLE void openExternal();

signals:
    void sourceChanged();
    void filePathChanged();
    void fileNameChanged();
    void pageCountChanged();
    void isLoadedChanged();
    void fileSizeChanged();
    void loadError(const QString &error);

#ifdef HAS_QT_PDF
private slots:
    void onStatusChanged(QPdfDocument::Status status);
#endif

private:
    QUrl m_source;
    QString m_filePath;
    QString m_fileName;
    int m_pageCount = 0;
    bool m_isLoaded = false;
    qint64 m_fileSize = 0;
#ifdef HAS_QT_PDF
    QPdfDocument *m_document = nullptr;
#endif
};

#endif // PDFDOCUMENT_H
