#include "AIManager.h"
#include "Settings.h"
#include "SubscriptionManager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QSslSocket>

AIManager* AIManager::s_instance = nullptr;

AIManager::AIManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_isLoading(false)
    , m_isImageBased(false)
{
}

AIManager* AIManager::instance()
{
    if (!s_instance) {
        s_instance = new AIManager();
    }
    return s_instance;
}

AIManager* AIManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    AIManager *inst = instance();
    QJSEngine::setObjectOwnership(inst, QJSEngine::CppOwnership);
    if (qmlEngine) {
        qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
    }
    return inst;
}

bool AIManager::isLoading() const { return m_isLoading; }

QString AIManager::currentPdfText() const { return m_currentPdfText; }

void AIManager::setCurrentPdfText(const QString &text)
{
    if (m_currentPdfText == text) return;
    m_currentPdfText = text;
    emit pdfTextChanged();
}

QString AIManager::currentResponse() const { return m_currentResponse; }

bool AIManager::isImageBased() const { return m_isImageBased; }

void AIManager::setIsImageBased(bool imageBased)
{
    if (m_isImageBased == imageBased) return;
    m_isImageBased = imageBased;
    emit imageBasedChanged();
}

QStringList AIManager::currentPageImages() const { return m_currentPageImages; }

void AIManager::setCurrentPageImages(const QStringList &images)
{
    m_currentPageImages = images;
    emit pageImagesChanged();
}

void AIManager::clearResponse()
{
    m_currentResponse.clear();
    emit responseChanged();
}

bool AIManager::checkAccessAndUsage()
{
    SubscriptionManager *sub = SubscriptionManager::instance();

    // Check if subscription is expired
    if (sub->status() == "expired") {
        emit accessDenied();
        return false;
    }

    // Check usage limit
    if (!sub->canMakeAIRequest()) {
        emit limitReached(sub->resetDate());
        return false;
    }

    return true;
}

QString AIManager::truncateText(const QString &text, int maxChars)
{
    if (text.length() <= maxChars) {
        return text;
    }

    QString truncated = text.left(maxChars);
    truncated += "\n\n[Note: Text was truncated to " + QString::number(maxChars) + " characters due to length limits]";
    return truncated;
}

void AIManager::summarizePdf()
{
    if (m_currentPdfText.isEmpty() && m_currentPageImages.isEmpty()) {
        emit errorOccurred(tr("No PDF content loaded. Please select a PDF first."));
        return;
    }

    if (!checkAccessAndUsage()) {
        return;
    }

    QString systemPrompt = "You are a PDF assistant. Provide a clear, structured summary of the document with:\n"
                           "1. Main topic/purpose\n"
                           "2. Key points (bullet list)\n"
                           "3. Important details or findings\n"
                           "4. Conclusion or takeaways\n\n"
                           "Keep the summary concise but comprehensive.";

    QString userMessage = "Please summarize this PDF document:\n\n";

    if (m_isImageBased && !m_currentPageImages.isEmpty()) {
        sendImageRequest(systemPrompt, "Please summarize this PDF document.");
    } else {
        userMessage += truncateText(m_currentPdfText);
        sendTextRequest(systemPrompt, userMessage);
    }
}

void AIManager::askQuestion(const QString &question)
{
    if (m_currentPdfText.isEmpty() && m_currentPageImages.isEmpty()) {
        emit errorOccurred(tr("No PDF content loaded. Please select a PDF first."));
        return;
    }

    if (question.trimmed().isEmpty()) {
        emit errorOccurred(tr("Please enter a question."));
        return;
    }

    if (!checkAccessAndUsage()) {
        return;
    }

    QString systemPrompt = "You are a PDF assistant. Answer questions based ONLY on the provided PDF content. "
                           "Be concise and accurate. If the answer is not found in the PDF, clearly state that. "
                           "Do not make up information.";

    if (m_isImageBased && !m_currentPageImages.isEmpty()) {
        sendImageRequest(systemPrompt, question);
    } else {
        QString userMessage = "PDF Content:\n" + truncateText(m_currentPdfText) +
                              "\n\n---\n\nQuestion: " + question;
        sendTextRequest(systemPrompt, userMessage);
    }
}

// API key from build-time environment variable
static QString getApiKey() {
#ifdef CLAUDE_API_KEY
    return QStringLiteral(CLAUDE_API_KEY);
#else
    // Fallback to settings
    return Settings::instance()->property("aiApiKey").toString();
#endif
}

void AIManager::sendTextRequest(const QString &systemPrompt, const QString &userMessage)
{
    QString apiKey = getApiKey();
    if (apiKey.isEmpty()) {
        emit errorOccurred(tr("AI service not configured. Please set up API key."));
        return;
    }

    // Check SSL support
    if (!QSslSocket::supportsSsl()) {
        qDebug() << "AIManager: SSL not supported!";
        emit errorOccurred(tr("SSL not available. Please ensure OpenSSL is installed."));
        return;
    }

    qDebug() << "AIManager: SSL supported. Version:" << QSslSocket::sslLibraryVersionString();

    // Cancel any existing request
    cancelRequest();

    m_isLoading = true;
    emit loadingChanged();

    QUrl url("https://api.anthropic.com/v1/messages");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("x-api-key", apiKey.toUtf8());
    request.setRawHeader("anthropic-version", "2023-06-01");

    QJsonObject json;
    json["model"] = "claude-sonnet-4-5-20250514";
    json["max_tokens"] = 1024;
    json["system"] = systemPrompt;

    QJsonArray messages;
    QJsonObject userMsg;
    userMsg["role"] = "user";
    userMsg["content"] = userMessage;
    messages.append(userMsg);

    json["messages"] = messages;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    qDebug() << "AIManager: Sending request to Claude API...";

    m_currentReply = m_networkManager->post(request, data);

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        handleResponse(m_currentReply);
    });
}

void AIManager::sendImageRequest(const QString &systemPrompt, const QString &userMessage)
{
    QString apiKey = getApiKey();
    if (apiKey.isEmpty()) {
        emit errorOccurred(tr("AI service not configured. Please set up API key."));
        return;
    }

    if (!QSslSocket::supportsSsl()) {
        emit errorOccurred(tr("SSL not available."));
        return;
    }

    cancelRequest();

    m_isLoading = true;
    emit loadingChanged();

    QUrl url("https://api.anthropic.com/v1/messages");
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("x-api-key", apiKey.toUtf8());
    request.setRawHeader("anthropic-version", "2023-06-01");

    QJsonObject json;
    json["model"] = "claude-sonnet-4-5-20250514";
    json["max_tokens"] = 1024;
    json["system"] = systemPrompt;

    // Build content array with images and text
    QJsonArray contentArray;

    // Add images (up to MAX_IMAGE_PAGES)
    int pageCount = qMin(static_cast<int>(m_currentPageImages.size()), static_cast<int>(MAX_IMAGE_PAGES));
    for (int i = 0; i < pageCount; ++i) {
        QJsonObject imageBlock;
        imageBlock["type"] = "image";

        QJsonObject source;
        source["type"] = "base64";
        source["media_type"] = "image/png";
        source["data"] = m_currentPageImages[i];
        imageBlock["source"] = source;

        contentArray.append(imageBlock);
    }

    if (m_currentPageImages.size() > static_cast<int>(MAX_IMAGE_PAGES)) {
        QJsonObject textBlock;
        textBlock["type"] = "text";
        textBlock["text"] = QString("[Note: Only showing first %1 pages of %2 total pages]")
                                .arg(MAX_IMAGE_PAGES).arg(m_currentPageImages.size());
        contentArray.append(textBlock);
    }

    // Add user's question/request
    QJsonObject textBlock;
    textBlock["type"] = "text";
    textBlock["text"] = userMessage;
    contentArray.append(textBlock);

    QJsonArray messages;
    QJsonObject userMsg;
    userMsg["role"] = "user";
    userMsg["content"] = contentArray;
    messages.append(userMsg);

    json["messages"] = messages;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    qDebug() << "AIManager: Sending image request to Claude API with" << pageCount << "pages...";

    m_currentReply = m_networkManager->post(request, data);

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        handleResponse(m_currentReply);
    });
}

void AIManager::handleResponse(QNetworkReply *reply)
{
    m_isLoading = false;
    emit loadingChanged();

    if (!reply) {
        emit errorOccurred(tr("Request was cancelled."));
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = reply->errorString();

        // Try to parse error response
        QByteArray responseData = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject error = doc.object()["error"].toObject();
            if (error.contains("message")) {
                errorMsg = error["message"].toString();
            }
        }

        qDebug() << "AIManager: API error:" << errorMsg;
        emit errorOccurred(tr("API Error: ") + errorMsg);
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);

    if (doc.isNull() || !doc.isObject()) {
        qDebug() << "AIManager: Invalid JSON response";
        emit errorOccurred(tr("Invalid response from AI service."));
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QJsonObject root = doc.object();

    // Claude API response format
    QJsonArray content = root["content"].toArray();

    if (content.isEmpty()) {
        qDebug() << "AIManager: No content in response";
        emit errorOccurred(tr("No response generated."));
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    // Extract text from first text block
    QString responseText;
    for (const QJsonValue &block : content) {
        QJsonObject blockObj = block.toObject();
        if (blockObj["type"].toString() == "text") {
            responseText = blockObj["text"].toString();
            break;
        }
    }

    if (responseText.isEmpty()) {
        qDebug() << "AIManager: Empty content in response";
        emit errorOccurred(tr("Empty response from AI."));
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    qDebug() << "AIManager: Response received successfully";

    m_currentResponse = responseText;
    emit responseChanged();
    emit responseReady(responseText);

    // Increment usage after successful response
    SubscriptionManager::instance()->incrementUsage();

    reply->deleteLater();
    m_currentReply = nullptr;
}

void AIManager::cancelRequest()
{
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;

        m_isLoading = false;
        emit loadingChanged();

        qDebug() << "AIManager: Request cancelled";
    }
}
