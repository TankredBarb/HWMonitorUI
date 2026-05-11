#pragma once

#include <QQuickImageProvider>
#include <QPixmap>
#include <QMap>
#include <QString>

class ProcessIconProvider : public QQuickImageProvider
{
public:
    ProcessIconProvider();

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;

    void updatePaths(const QMap<QString, QString> &nameToPath);
    void clearCache();

private:
    QMap<QString, QString> m_nameToPath;
    QMap<QString, QPixmap> m_cache;

    QPixmap defaultIcon();
};
