#include "PDFDocument.h"
#include <QFileInfo>
#include <QFile>
#include <QDesktopServices>

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
    qDebug() << "PDFDocument::setSource - URL:" << source << "LocalFile:" << path;
    if (path.isEmpty() && source.scheme() == "content") {
        path = source.toString();
        qDebug() << "PDFDocument::setSource - Using content URL as path:" << path;
    }

    m_filePath = path;
    emit filePathChanged();

    QFileInfo info(path);
    m_fileName = info.fileName();
    emit fileNameChanged();

    qDebug() << "PDFDocument::setSource - Checking if file exists:" << path << "Exists:" << QFile::exists(path);
    if (QFile::exists(path)) {
        m_fileSize = info.size();
        emit fileSizeChanged();
#ifdef HAS_QT_PDF
        m_document->load(path);
#else
        // On Android, we don't have built-in PDF viewing
        // Set as loaded so the UI can offer to open externally
        m_isLoaded = true;
        m_pageCount = 1; // Unknown, set to 1
        emit isLoadedChanged();
        emit pageCountChanged();
        qDebug() << "PDFDocument::setSource - File loaded successfully (external mode)";
#endif
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
