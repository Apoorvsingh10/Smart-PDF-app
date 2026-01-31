#ifndef MAINVIEWMODEL_H
#define MAINVIEWMODEL_H

#include <QObject>
#include <QtQml>
#include "../core/PDFEngine.h"

class MainViewModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int currentTabIndex READ currentTabIndex WRITE setCurrentTabIndex NOTIFY currentTabIndexChanged)
    Q_PROPERTY(bool isPro READ isPro WRITE setIsPro NOTIFY isProChanged)
    Q_PROPERTY(PDFEngine* pdfEngine READ pdfEngine CONSTANT)

public:
    explicit MainViewModel(QObject *parent = nullptr);

    int currentTabIndex() const { return m_currentTabIndex; }
    void setCurrentTabIndex(int index);

    bool isPro() const { return m_isPro; }
    void setIsPro(bool value);

    PDFEngine* pdfEngine() const { return m_pdfEngine; }

    Q_INVOKABLE void navigateTo(const QString &screen);

signals:
    void currentTabIndexChanged();
    void isProChanged();
    void navigationRequested(const QString &screen);

private:
    int m_currentTabIndex = 0;
    bool m_isPro = false;
    PDFEngine *m_pdfEngine;
};

#endif // MAINVIEWMODEL_H
