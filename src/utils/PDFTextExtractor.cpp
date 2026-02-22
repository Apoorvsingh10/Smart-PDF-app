#include "PDFTextExtractor.h"
#include <QFile>
#include <QFileInfo>
#include <QDebug>
#include <QThread>
#include <QBuffer>
#include <QImage>

#ifdef HAS_QT_PDF
#include <QPdfDocument>
#include <QPdfSelection>
#endif

PDFTextExtractor* PDFTextExtractor::s_instance = nullptr;

PDFTextExtractor::PDFTextExtractor(QObject *parent)
    : QObject(parent)
    , m_isImageBased(false)
    , m_pageCount(0)
    , m_isExtracting(false)
{
}

PDFTextExtractor* PDFTextExtractor::instance()
{
    if (!s_instance) {
        s_instance = new PDFTextExtractor();
    }
    return s_instance;
}

PDFTextExtractor* PDFTextExtractor::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    PDFTextExtractor *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

bool PDFTextExtractor::isImageBased() const { return m_isImageBased; }
QString PDFTextExtractor::extractedText() const { return m_extractedText; }
QStringList PDFTextExtractor::pageImages() const { return m_pageImages; }
int PDFTextExtractor::pageCount() const { return m_pageCount; }
bool PDFTextExtractor::isExtracting() const { return m_isExtracting; }

QString PDFTextExtractor::urlToLocalPath(const QUrl &url)
{
    // Use Qt's built-in conversion first
    QString path = url.toLocalFile();

    qDebug() << "PDFTextExtractor: URL:" << url << "toLocalFile:" << path;

    // If toLocalFile returns empty (e.g., for content:// on Android), use the URL string
    if (path.isEmpty()) {
        if (url.scheme() == "content") {
            // For Android content URIs, use the full URL string
            // QPdfDocument can handle these on Android
            path = url.toString();
            qDebug() << "PDFTextExtractor: Using content URI:" << path;
        } else {
            // Fallback: try to extract path from URL string
            path = url.toString();
            if (path.startsWith("file:///")) {
#ifdef Q_OS_WIN
                path = path.mid(8);
#else
                path = path.mid(7);
#endif
            } else if (path.startsWith("file://")) {
                path = path.mid(7);
            }
            qDebug() << "PDFTextExtractor: Fallback path extraction:" << path;
        }
    }

    return path;
}

void PDFTextExtractor::extractFromUrl(const QUrl &fileUrl)
{
    QString path = urlToLocalPath(fileUrl);
    if (path.isEmpty()) {
        emit errorOccurred(tr("Could not convert URL to path"));
        return;
    }
    extract(path);
}

void PDFTextExtractor::extract(const QString &filePath)
{
    qDebug() << "PDFTextExtractor: Starting extraction from:" << filePath;

    m_isExtracting = true;
    emit extractingChanged();

    // Clear previous data
    m_extractedText.clear();
    m_pageImages.clear();
    m_isImageBased = false;
    m_pageCount = 0;

#ifdef HAS_QT_PDF
    QPdfDocument doc;
    QPdfDocument::Error error = doc.load(filePath);

    // Wait for document to be ready (synchronous loading)
    int timeout = 50; // 5 seconds max
    while (doc.status() == QPdfDocument::Status::Loading && timeout > 0) {
        QThread::msleep(100);
        timeout--;
    }

    if (doc.status() != QPdfDocument::Status::Ready) {
        qDebug() << "PDFTextExtractor: Failed to load PDF. Status:" << static_cast<int>(doc.status());
        m_isExtracting = false;
        emit extractingChanged();
        emit errorOccurred(tr("Failed to load PDF"));
        return;
    }

    m_pageCount = doc.pageCount();
    qDebug() << "PDFTextExtractor: Document loaded with" << m_pageCount << "pages";

    // First, try to extract text
    QString fullText;
    for (int i = 0; i < m_pageCount; ++i) {
        QPdfSelection selection = doc.getAllText(i);
        QString pageText = selection.text();

        if (!pageText.isEmpty()) {
            if (!fullText.isEmpty()) {
                fullText += "\n\n";
            }
            fullText += "--- Page " + QString::number(i + 1) + " ---\n";
            fullText += pageText;
        }
    }

    qDebug() << "PDFTextExtractor: Extracted" << fullText.length() << "characters of text";

    // If text is too short, it's likely an image-based PDF
    if (fullText.length() < MIN_TEXT_LENGTH) {
        qDebug() << "PDFTextExtractor: Text too short, treating as image-based PDF";
        m_isImageBased = true;
        m_pageImages = extractPagesAsImages(filePath);
    } else {
        m_isImageBased = false;
        m_extractedText = fullText;
    }

#else
    qDebug() << "PDFTextExtractor: Qt PDF module not available";
    m_isExtracting = false;
    emit extractingChanged();
    emit errorOccurred(tr("PDF module not available"));
    return;
#endif

    m_isExtracting = false;
    emit extractingChanged();
    emit extractionComplete();
}

QStringList PDFTextExtractor::extractPagesAsImages(const QString &path)
{
    QStringList images;

#ifdef HAS_QT_PDF
    QPdfDocument doc;
    doc.load(path);

    int timeout = 50;
    while (doc.status() == QPdfDocument::Status::Loading && timeout > 0) {
        QThread::msleep(100);
        timeout--;
    }

    if (doc.status() != QPdfDocument::Status::Ready) {
        return images;
    }

    int pageCount = qMin(doc.pageCount(), static_cast<int>(MAX_IMAGE_PAGES));
    qDebug() << "PDFTextExtractor: Rendering" << pageCount << "pages as images";

    for (int i = 0; i < pageCount; ++i) {
        QSizeF pageSize = doc.pagePointSize(i);

        // Render at 2x scale for quality (max 2000px width to avoid memory issues)
        qreal scale = 2.0;
        int maxWidth = 2000;
        if (pageSize.width() * scale > maxWidth) {
            scale = maxWidth / pageSize.width();
        }

        QSize renderSize(pageSize.width() * scale, pageSize.height() * scale);
        QImage image = doc.render(i, renderSize);

        if (!image.isNull()) {
            // Convert to PNG and base64 encode
            QByteArray ba;
            QBuffer buffer(&ba);
            buffer.open(QIODevice::WriteOnly);
            image.save(&buffer, "PNG", 80); // 80% quality

            QString base64 = QString::fromLatin1(ba.toBase64());
            images.append(base64);

            qDebug() << "PDFTextExtractor: Page" << (i + 1) << "rendered, size:" << ba.size() / 1024 << "KB";
        }
    }

#endif

    return images;
}

QString PDFTextExtractor::extractTextFromUrl(const QUrl &fileUrl)
{
    QString path = urlToLocalPath(fileUrl);
    if (path.isEmpty()) {
        qDebug() << "PDFTextExtractor: Could not convert URL to path";
        return QString();
    }
    return extractText(path);
}

QString PDFTextExtractor::extractText(const QString &filePath)
{
    qDebug() << "PDFTextExtractor: Extracting text from:" << filePath;

#ifdef HAS_QT_PDF
    return extractWithQPdf(filePath);
#else
    qDebug() << "PDFTextExtractor: Qt PDF module not available";
    return QString();
#endif
}

int PDFTextExtractor::getPageCount(const QString &filePath)
{
#ifdef HAS_QT_PDF
    QPdfDocument doc;
    QPdfDocument::Error error = doc.load(filePath);

    if (error != QPdfDocument::Error::None) {
        qDebug() << "PDFTextExtractor: Failed to load PDF for page count";
        return 0;
    }

    return doc.pageCount();
#else
    Q_UNUSED(filePath)
    return 0;
#endif
}

QString PDFTextExtractor::extractWithQPdf(const QString &path)
{
#ifdef HAS_QT_PDF
    qDebug() << "PDFTextExtractor: Loading PDF from:" << path;

    QPdfDocument doc;
    QPdfDocument::Error error = doc.load(path);

    // Wait for document to be ready (synchronous loading)
    int timeout = 50; // 5 seconds max
    while (doc.status() == QPdfDocument::Status::Loading && timeout > 0) {
        QThread::msleep(100);
        timeout--;
    }

    if (doc.status() != QPdfDocument::Status::Ready) {
        qDebug() << "PDFTextExtractor: Failed to load PDF. Status:" << static_cast<int>(doc.status())
                 << "Error:" << static_cast<int>(error);
        return QString();
    }

    QString fullText;
    int pageCount = doc.pageCount();

    qDebug() << "PDFTextExtractor: Document loaded successfully with" << pageCount << "pages";

    for (int i = 0; i < pageCount; ++i) {
        // Select all text on the page
        QPdfSelection selection = doc.getAllText(i);
        QString pageText = selection.text();

        qDebug() << "PDFTextExtractor: Page" << (i + 1) << "extracted" << pageText.length() << "chars";

        if (!pageText.isEmpty()) {
            if (!fullText.isEmpty()) {
                fullText += "\n\n";
            }
            fullText += "--- Page " + QString::number(i + 1) + " ---\n";
            fullText += pageText;
        }
    }

    qDebug() << "PDFTextExtractor: Total extracted" << fullText.length() << "characters";

    if (fullText.isEmpty()) {
        qDebug() << "PDFTextExtractor: No text extracted (PDF may be image-based or scanned)";
    }

    return fullText;
#else
    Q_UNUSED(path)
    qDebug() << "PDFTextExtractor: HAS_QT_PDF not defined - cannot extract text";
    return QString();
#endif
}
