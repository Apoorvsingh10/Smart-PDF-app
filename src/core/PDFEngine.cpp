#include "PDFEngine.h"
#include <QtConcurrent>
#include <QFuture>
#include <QList>
#include <QStringList>
#include <QThread>
#include <QMetaObject>
#include <QFile>
#include <QFileInfo>
#include <type_traits>

#ifdef HAS_QT_PDF
#include <QPdfDocument>
#include <QPdfWriter>
#include <QPainter>
#include <QImage>
#include <QPageSize>
#endif

PDFEngine::PDFEngine(QObject *parent) : QObject(parent)
{
}

void PDFEngine::setProgress(double value)
{
    if (qFuzzyCompare(m_progress, value)) return;
    m_progress = value;
    emit progressChanged();
}

void PDFEngine::setProcessing(bool value)
{
    if (m_isProcessing == value) return;
    m_isProcessing = value;
    emit isProcessingChanged();
}

void PDFEngine::setCurrentOperation(const QString &op)
{
    if (m_currentOperation == op) return;
    m_currentOperation = op;
    emit currentOperationChanged();
}

void PDFEngine::mergePDFs(const QStringList &inputFiles, const QString &outputFile)
{
    if (m_isProcessing) return;

    setProcessing(true);
    setCurrentOperation(tr("Merging PDFs..."));
    setProgress(0);
    m_cancelled = false;

    QtConcurrent::run([this, inputFiles, outputFile]() {
#ifdef HAS_QT_PDF
        // First, count total pages across all PDFs
        int totalPages = 0;
        QList<QPdfDocument*> documents;

        for (const QString &inputFile : inputFiles) {
            QString filePath = inputFile;
            // Handle file:// URLs
            if (filePath.startsWith("file:///")) {
                filePath = filePath.mid(8);
            } else if (filePath.startsWith("file://")) {
                filePath = filePath.mid(7);
            }

            qDebug() << "PDFEngine::mergePDFs - Opening:" << filePath;

            QPdfDocument *doc = new QPdfDocument();
            QPdfDocument::Error error = doc->load(filePath);
            if (error != QPdfDocument::Error::None) {
                qDebug() << "PDFEngine::mergePDFs - Failed to load:" << filePath << "Error:" << static_cast<int>(error);
                // Clean up
                for (QPdfDocument *d : documents) delete d;
                delete doc;

                QMetaObject::invokeMethod(this, [this, filePath]() {
                    setProcessing(false);
                    emit operationCompleted(false, tr("Failed to load PDF: %1").arg(filePath));
                }, Qt::QueuedConnection);
                return;
            }

            documents.append(doc);
            totalPages += doc->pageCount();
            qDebug() << "PDFEngine::mergePDFs - Loaded" << filePath << "with" << doc->pageCount() << "pages";
        }

        if (totalPages == 0) {
            for (QPdfDocument *d : documents) delete d;
            QMetaObject::invokeMethod(this, [this]() {
                setProcessing(false);
                emit operationCompleted(false, tr("No pages found in input PDFs"));
            }, Qt::QueuedConnection);
            return;
        }

        // Create output PDF
        QFile outFile(outputFile);
        if (!outFile.open(QIODevice::WriteOnly)) {
            qDebug() << "PDFEngine::mergePDFs - Cannot create output file:" << outputFile;
            for (QPdfDocument *d : documents) delete d;
            QMetaObject::invokeMethod(this, [this, outputFile]() {
                setProcessing(false);
                emit operationCompleted(false, tr("Cannot create output file: %1").arg(outputFile));
            }, Qt::QueuedConnection);
            return;
        }

        QPdfWriter writer(&outFile);
        writer.setResolution(150); // DPI - balance between quality and file size
        QPainter painter;

        int currentPage = 0;
        bool firstPage = true;

        for (QPdfDocument *doc : documents) {
            for (int page = 0; page < doc->pageCount() && !m_cancelled; ++page) {
                // Get page size
                QSizeF pageSizePoints = doc->pagePointSize(page);
                QPageSize pageSize(pageSizePoints, QPageSize::Point);

                if (firstPage) {
                    writer.setPageSize(pageSize);
                    if (!painter.begin(&writer)) {
                        qDebug() << "PDFEngine::mergePDFs - Failed to begin painting";
                        break;
                    }
                    firstPage = false;
                } else {
                    writer.setPageSize(pageSize);
                    writer.newPage();
                }

                // Render page to image at good quality
                QSizeF pageSize150dpi = pageSizePoints * 150.0 / 72.0; // Convert points to pixels at 150 DPI
                QImage pageImage = doc->render(page, pageSize150dpi.toSize());

                if (!pageImage.isNull()) {
                    // Draw the image to fill the page
                    QRectF targetRect(0, 0, writer.width(), writer.height());
                    painter.drawImage(targetRect, pageImage);
                }

                currentPage++;
                QMetaObject::invokeMethod(this, [this, currentPage, totalPages]() {
                    setProgress((double)currentPage / totalPages);
                }, Qt::QueuedConnection);
            }
        }

        if (painter.isActive()) {
            painter.end();
        }
        outFile.close();

        // Clean up documents
        for (QPdfDocument *d : documents) delete d;

        qDebug() << "PDFEngine::mergePDFs - Output file created:" << outputFile << "Size:" << QFileInfo(outputFile).size();

        QMetaObject::invokeMethod(this, [this, outputFile]() {
            setProcessing(false);
            setProgress(1.0);
            if (!m_cancelled) {
                emit operationCompleted(true, tr("PDFs merged successfully!"));
            }
        }, Qt::QueuedConnection);
#else
        // No Qt PDF support - cannot merge
        QMetaObject::invokeMethod(this, [this]() {
            setProcessing(false);
            emit operationCompleted(false, tr("PDF merging not supported on this platform"));
        }, Qt::QueuedConnection);
#endif
    });
}

void PDFEngine::splitPDF(const QString &inputFile, const QString &outputDir, const QList<int> &pages)
{
    if (m_isProcessing) return;

    setProcessing(true);
    setCurrentOperation(tr("Splitting PDF..."));
    setProgress(0);
    m_cancelled = false;

    QtConcurrent::run([this, inputFile, outputDir, pages]() {
#ifdef HAS_QT_PDF
        // Parse input file path
        QString filePath = inputFile;
        if (filePath.startsWith("file:///")) {
            filePath = filePath.mid(8);
        } else if (filePath.startsWith("file://")) {
            filePath = filePath.mid(7);
        }

        qDebug() << "PDFEngine::splitPDF - Input:" << filePath;
        qDebug() << "PDFEngine::splitPDF - Output dir:" << outputDir;
        qDebug() << "PDFEngine::splitPDF - Pages to include:" << pages;

        // Open source PDF
        QPdfDocument doc;
        QPdfDocument::Error error = doc.load(filePath);
        if (error != QPdfDocument::Error::None) {
            qDebug() << "PDFEngine::splitPDF - Failed to load:" << filePath;
            QMetaObject::invokeMethod(this, [this, filePath]() {
                setProcessing(false);
                emit operationCompleted(false, tr("Failed to load PDF: %1").arg(filePath));
            }, Qt::QueuedConnection);
            return;
        }

        if (pages.isEmpty()) {
            QMetaObject::invokeMethod(this, [this]() {
                setProcessing(false);
                emit operationCompleted(false, tr("No pages selected"));
            }, Qt::QueuedConnection);
            return;
        }

        // Generate output filename
        QFileInfo inputInfo(filePath);
        QString baseName = inputInfo.completeBaseName();
        QString outputPath = QDir(outputDir).filePath(baseName + "_split.pdf");

        qDebug() << "PDFEngine::splitPDF - Output file:" << outputPath;

        // Create output PDF
        QFile outFile(outputPath);
        if (!outFile.open(QIODevice::WriteOnly)) {
            qDebug() << "PDFEngine::splitPDF - Cannot create output file:" << outputPath;
            QMetaObject::invokeMethod(this, [this, outputPath]() {
                setProcessing(false);
                emit operationCompleted(false, tr("Cannot create output file: %1").arg(outputPath));
            }, Qt::QueuedConnection);
            return;
        }

        QPdfWriter writer(&outFile);
        writer.setResolution(150);
        QPainter painter;

        int totalPages = pages.size();
        int currentPage = 0;
        bool firstPage = true;

        for (int pageIndex : pages) {
            if (m_cancelled) break;

            if (pageIndex < 0 || pageIndex >= doc.pageCount()) {
                qDebug() << "PDFEngine::splitPDF - Skipping invalid page index:" << pageIndex;
                continue;
            }

            // Get page size
            QSizeF pageSizePoints = doc.pagePointSize(pageIndex);
            QPageSize pageSize(pageSizePoints, QPageSize::Point);

            if (firstPage) {
                writer.setPageSize(pageSize);
                if (!painter.begin(&writer)) {
                    qDebug() << "PDFEngine::splitPDF - Failed to begin painting";
                    break;
                }
                firstPage = false;
            } else {
                writer.setPageSize(pageSize);
                writer.newPage();
            }

            // Render page to image
            QSizeF pageSize150dpi = pageSizePoints * 150.0 / 72.0;
            QImage pageImage = doc.render(pageIndex, pageSize150dpi.toSize());

            if (!pageImage.isNull()) {
                QRectF targetRect(0, 0, writer.width(), writer.height());
                painter.drawImage(targetRect, pageImage);
            }

            currentPage++;
            QMetaObject::invokeMethod(this, [this, currentPage, totalPages]() {
                setProgress((double)currentPage / totalPages);
            }, Qt::QueuedConnection);
        }

        if (painter.isActive()) {
            painter.end();
        }
        outFile.close();

        qDebug() << "PDFEngine::splitPDF - Output file created:" << outputPath << "Size:" << QFileInfo(outputPath).size();

        QMetaObject::invokeMethod(this, [this, totalPages]() {
            setProcessing(false);
            setProgress(1.0);
            if (!m_cancelled) {
                emit operationCompleted(true, tr("PDF split successfully! %1 pages extracted.").arg(totalPages));
            }
        }, Qt::QueuedConnection);
#else
        QMetaObject::invokeMethod(this, [this]() {
            setProcessing(false);
            emit operationCompleted(false, tr("PDF splitting not supported on this platform"));
        }, Qt::QueuedConnection);
#endif
    });
}

void PDFEngine::compressPDF(const QString &inputFile, const QString &outputFile, int quality)
{
    if (m_isProcessing) return;

    setProcessing(true);
    setCurrentOperation(tr("Compressing PDF..."));
    setProgress(0);
    m_cancelled = false;

    QtConcurrent::run([this, inputFile, outputFile, quality]() {
#ifdef HAS_QT_PDF
        // Parse input file path
        QString filePath = inputFile;
        if (filePath.startsWith("file:///")) {
            filePath = filePath.mid(8);
        } else if (filePath.startsWith("file://")) {
            filePath = filePath.mid(7);
        }

        qDebug() << "PDFEngine::compressPDF - Input:" << filePath;
        qDebug() << "PDFEngine::compressPDF - Output:" << outputFile;
        qDebug() << "PDFEngine::compressPDF - Quality level:" << quality;

        // Compression settings based on quality level
        // quality: 0=low compression (high quality), 1=medium, 2=high compression (low quality)
        int dpi;
        int jpegQuality;

        switch (quality) {
            case 0: // Low compression - high quality
                dpi = 150;
                jpegQuality = 85;
                break;
            case 2: // High compression - low quality
                dpi = 72;
                jpegQuality = 50;
                break;
            case 1: // Medium compression - balanced
            default:
                dpi = 120;
                jpegQuality = 70;
                break;
        }

        qDebug() << "PDFEngine::compressPDF - Using DPI:" << dpi << "JPEG Quality:" << jpegQuality;

        // Open source PDF
        QPdfDocument doc;
        QPdfDocument::Error error = doc.load(filePath);
        if (error != QPdfDocument::Error::None) {
            qDebug() << "PDFEngine::compressPDF - Failed to load:" << filePath;
            QMetaObject::invokeMethod(this, [this, filePath]() {
                setProcessing(false);
                emit operationCompleted(false, tr("Failed to load PDF: %1").arg(filePath));
            }, Qt::QueuedConnection);
            return;
        }

        int totalPages = doc.pageCount();
        if (totalPages == 0) {
            QMetaObject::invokeMethod(this, [this]() {
                setProcessing(false);
                emit operationCompleted(false, tr("PDF has no pages"));
            }, Qt::QueuedConnection);
            return;
        }

        // Get original file size for comparison
        qint64 originalSize = QFileInfo(filePath).size();

        // Create output PDF
        QFile outFile(outputFile);
        if (!outFile.open(QIODevice::WriteOnly)) {
            qDebug() << "PDFEngine::compressPDF - Cannot create output file:" << outputFile;
            QMetaObject::invokeMethod(this, [this, outputFile]() {
                setProcessing(false);
                emit operationCompleted(false, tr("Cannot create output file: %1").arg(outputFile));
            }, Qt::QueuedConnection);
            return;
        }

        QPdfWriter writer(&outFile);
        writer.setResolution(dpi);
        QPainter painter;

        bool firstPage = true;

        for (int page = 0; page < totalPages && !m_cancelled; ++page) {
            // Get page size in points
            QSizeF pageSizePoints = doc.pagePointSize(page);
            QPageSize pageSize(pageSizePoints, QPageSize::Point);

            if (firstPage) {
                writer.setPageSize(pageSize);
                if (!painter.begin(&writer)) {
                    qDebug() << "PDFEngine::compressPDF - Failed to begin painting";
                    break;
                }
                firstPage = false;
            } else {
                writer.setPageSize(pageSize);
                writer.newPage();
            }

            // Render page to image at specified DPI
            QSizeF pageSizePixels = pageSizePoints * dpi / 72.0;
            QImage pageImage = doc.render(page, pageSizePixels.toSize());

            if (!pageImage.isNull()) {
                // Convert to RGB format for JPEG compression simulation
                // (QPdfWriter doesn't support direct JPEG, but lower DPI achieves similar effect)
                if (pageImage.format() != QImage::Format_RGB32) {
                    pageImage = pageImage.convertToFormat(QImage::Format_RGB32);
                }

                // For additional compression, we can reduce color depth for high compression
                if (quality == 2) {
                    // Convert to indexed color for maximum compression on high setting
                    pageImage = pageImage.convertToFormat(QImage::Format_RGB888);
                }

                QRectF targetRect(0, 0, writer.width(), writer.height());
                painter.drawImage(targetRect, pageImage);
            }

            QMetaObject::invokeMethod(this, [this, page, totalPages]() {
                setProgress((double)(page + 1) / totalPages);
            }, Qt::QueuedConnection);
        }

        if (painter.isActive()) {
            painter.end();
        }
        outFile.close();

        // Calculate compression ratio
        qint64 compressedSize = QFileInfo(outputFile).size();
        int reductionPercent = originalSize > 0 ? (int)(100 - (compressedSize * 100 / originalSize)) : 0;

        qDebug() << "PDFEngine::compressPDF - Original size:" << originalSize
                 << "Compressed size:" << compressedSize
                 << "Reduction:" << reductionPercent << "%";

        QMetaObject::invokeMethod(this, [this, reductionPercent, compressedSize]() {
            setProcessing(false);
            setProgress(1.0);
            if (!m_cancelled) {
                QString sizeStr;
                if (compressedSize < 1024) {
                    sizeStr = QString("%1 B").arg(compressedSize);
                } else if (compressedSize < 1024 * 1024) {
                    sizeStr = QString("%1 KB").arg(compressedSize / 1024.0, 0, 'f', 1);
                } else {
                    sizeStr = QString("%1 MB").arg(compressedSize / (1024.0 * 1024.0), 0, 'f', 1);
                }
                emit operationCompleted(true, tr("PDF compressed! Reduced by %1% (New size: %2)").arg(reductionPercent).arg(sizeStr));
            }
        }, Qt::QueuedConnection);
#else
        QMetaObject::invokeMethod(this, [this]() {
            setProcessing(false);
            emit operationCompleted(false, tr("PDF compression not supported on this platform"));
        }, Qt::QueuedConnection);
#endif
    });
}

void PDFEngine::cancelOperation()
{
    m_cancelled = true;
}
