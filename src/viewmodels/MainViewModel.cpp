#include "MainViewModel.h"

MainViewModel::MainViewModel(QObject *parent) : QObject(parent)
{
    m_pdfEngine = new PDFEngine(this);
}

void MainViewModel::setCurrentTabIndex(int index)
{
    if (m_currentTabIndex == index) return;
    m_currentTabIndex = index;
    emit currentTabIndexChanged();
}

void MainViewModel::setIsPro(bool value)
{
    if (m_isPro == value) return;
    m_isPro = value;
    emit isProChanged();
}

void MainViewModel::navigateTo(const QString &screen)
{
    emit navigationRequested(screen);
}
