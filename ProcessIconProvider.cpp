#include "ProcessIconProvider.h"
#include <QImage>
#include <QPixmap>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>
#endif

ProcessIconProvider::ProcessIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

void ProcessIconProvider::updatePaths(const QMap<QString, QString> &nameToPath)
{
    m_nameToPath = nameToPath;
}

void ProcessIconProvider::clearCache()
{
    m_cache.clear();
}

QPixmap ProcessIconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)

    if (size)
        *size = QSize(16, 16);

    if (m_cache.contains(id))
        return m_cache[id];

#ifdef Q_OS_WIN
    SHFILEINFOW sfi = {};
    DWORD flags = SHGFI_ICON | SHGFI_SMALLICON | SHGFI_USEFILEATTRIBUTES;

    QString path = m_nameToPath.value(id);
    if (!path.isEmpty())
    {
        flags &= ~SHGFI_USEFILEATTRIBUTES;
        if (SHGetFileInfoW((LPCWSTR)path.utf16(), 0, &sfi, sizeof(sfi), flags))
        {
            QImage img = QImage::fromHICON(sfi.hIcon);
            DestroyIcon(sfi.hIcon);
            if (!img.isNull())
            {
                QPixmap pix = QPixmap::fromImage(img);
                m_cache[id] = pix;
                return pix;
            }
        }
    }

    if (SHGetFileInfoW((LPCWSTR)id.utf16(), FILE_ATTRIBUTE_NORMAL, &sfi, sizeof(sfi),
                       SHGFI_ICON | SHGFI_SMALLICON | SHGFI_USEFILEATTRIBUTES | SHGFI_EXETYPE))
    {
        QImage img = QImage::fromHICON(sfi.hIcon);
        DestroyIcon(sfi.hIcon);
        if (!img.isNull())
        {
            QPixmap pix = QPixmap::fromImage(img);
            m_cache[id] = pix;
            return pix;
        }
    }
#endif

    return defaultIcon();
}

QPixmap ProcessIconProvider::defaultIcon()
{
    static QPixmap def;
    if (def.isNull())
    {
        def = QPixmap(16, 16);
        def.fill(Qt::transparent);
    }
    return def;
}
