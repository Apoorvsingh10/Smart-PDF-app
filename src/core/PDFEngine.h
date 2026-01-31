#ifndef PDFENGINE_H
#define PDFENGINE_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QtQml>

class PDFEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool isProcessing READ isProcessing NOTIFY isProcessingChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString currentOperation READ currentOperation NOTIFY currentOperationChanged)

public:
    explicit PDFEngine(QObject *parent = nullptr);

    bool isProcessing() const { return m_isProcessing; }
    double progress() const { return m_progress; }
    QString currentOperation() const { return m_currentOperation; }

    Q_INVOKABLE void mergePDFs(const QStringList &inputFiles, const QString &outputFile);
    Q_INVOKABLE void splitPDF(const QString &inputFile, const QString &outputDir, const QList<int> &pages);
    Q_INVOKABLE void compressPDF(const QString &inputFile, const QString &outputFile, int quality);
    Q_INVOKABLE void cancelOperation();

signals:
    void isProcessingChanged();
    void progressChanged();
    void currentOperationChanged();
    void operationCompleted(bool success, const QString &message);
    void operationError(const QString &error);

private:
    void setProgress(double value);
    void setProcessing(bool value);
    void setCurrentOperation(const QString &op);

    bool m_isProcessing = false;
    double m_progress = 0.0;
    QString m_currentOperation;
    bool m_cancelled = false;
};

#endif // PDFENGINE_H
