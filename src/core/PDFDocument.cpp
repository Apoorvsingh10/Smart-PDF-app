#include "PDFDocument.h"
#include <QFileInfo>
#include <QFile>
#include <QDesktopServices>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QCoreApplication>
#endif

PDFDocument::PDFDocument(QObject *parent) : QObject(parent)
{
#ifdef HAS_QT_PDF
    m_document = new QPdfDocument(this);
    connect(m_document, &QPdfDocument::statusChanged, this, &PDFDocument::onStatusChanged);
#endif
}

PDFDocument::~PDFDocument()
{
}

void PDFDocument::setSource(const QUrl &source)
{
    if (m_source == source) return;

    m_source = source;
    emit sourceChanged();

    QString path = source.toLocalFile();
    bool isContentUri = (source.scheme() == "content");

    qDebug() << "PDFDocument::setSource - URL:" << source << "LocalFile:" << path << "isContentUri:" << isContentUri;

    if (path.isEmpty() && isContentUri) {
        path = source.toString();
        qDebug() << "PDFDocument::setSource - Using content URL as path:" << path;
    }

    m_filePath = path;
    emit filePathChanged();

    // Extract filename from content URI or file path
    if (isContentUri) {
        // For content URIs, try to extract filename from the path
        QString uriPath = source.path();
        int lastSlash = uriPath.lastIndexOf('/');
        if (lastSlash >= 0) {
            m_fileName = QUrl::fromPercentEncoding(uriPath.mid(lastSlash + 1).toUtf8());
        } else {
            m_fileName = "document.pdf";
        }
    } else {
        QFileInfo info(path);
        m_fileName = info.fileName();
    }
    emit fileNameChanged();

    // For content:// URIs on Android, we can't use QFile::exists()
    // Instead, try to load directly - Qt handles content:// URIs internally
    bool canLoad = false;

    if (isContentUri) {
#ifdef Q_OS_ANDROID
        qDebug() << "PDFDocument::setSource - Android content URI, attempting direct load";
        canLoad = true;  // Try to load directly, let Qt handle it
#else
        qDebug() << "PDFDocument::setSource - Content URI not supported on this platform";
        emit loadError(tr("Content URIs not supported on this platform"));
        return;
#endif
    } else {
        // Regular file path
        canLoad = QFile::exists(path);
        qDebug() << "PDFDocument::setSource - Checking if file exists:" << path << "Exists:" << canLoad;
        if (canLoad) {
            QFileInfo info(path);
            m_fileSize = info.size();
            emit fileSizeChanged();
        }
    }

    if (canLoad) {
        // Don't load PDF here - let PdfDocument in QML handle the actual loading
        // This avoids loading the PDF twice which causes slowness
        m_isLoaded = true;
        m_pageCount = 1;  // Actual count comes from pdfViewerDocument in QML
        emit isLoadedChanged();
        emit pageCountChanged();
        qDebug() << "PDFDocument::setSource - File ready for viewing";
    } else {
        qDebug() << "PDFDocument::setSource - FILE NOT FOUND!";
        emit loadError(tr("File not found: %1").arg(path));
    }
}

void PDFDocument::close()
{
#ifdef HAS_QT_PDF
    m_document->close();
#endif
    m_source = QUrl();
    m_filePath.clear();
    m_fileName.clear();
    m_pageCount = 0;
    m_isLoaded = false;
    m_fileSize = 0;

    emit sourceChanged();
    emit filePathChanged();
    emit fileNameChanged();
    emit pageCountChanged();
    emit isLoadedChanged();
    emit fileSizeChanged();
}

void PDFDocument::openExternal()
{
    if (!m_source.isEmpty()) {
        QDesktopServices::openUrl(m_source);
    }
}

#ifdef HAS_QT_PDF
void PDFDocument::onStatusChanged(QPdfDocument::Status status)
{
    if (status == QPdfDocument::Status::Ready) {
        m_pageCount = m_document->pageCount();
        m_isLoaded = true;
        emit pageCountChanged();
        emit isLoadedChanged();
    } else if (status == QPdfDocument::Status::Error) {
        m_isLoaded = false;
        emit isLoadedChanged();
        emit loadError(tr("Failed to load PDF"));
    }
}
#endif
