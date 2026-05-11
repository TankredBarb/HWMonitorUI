#pragma once

#include <QObject>
#include <QVariantList>
#include <QDateTime>
#include <QMap>

#ifdef Q_OS_WIN
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>
#endif

struct ProcessInfo {
    uint32_t pid;
    QString name;
    double cpuUsage;
    double workingSetMb;
    double privateBytesMb;
    QList<uint32_t> multiPids;
};

class ProcessMonitor : public QObject {
    Q_OBJECT
public:
    explicit ProcessMonitor(QObject *parent = nullptr);
    
    QVariantList getCpuProcesses();
    QVariantList getMemoryProcesses();
    double getTotalRamMb();
    
    void update();

private:
#ifdef Q_OS_WIN
    struct ProcessTimeInfo {
        ULONGLONG lastTime;
        ULONGLONG lastSystemTime;
    };
    QMap<uint32_t, ProcessTimeInfo> m_processTimeMap;
    ULONGLONG m_lastSystemTime = 0;
#endif

    QList<ProcessInfo> m_processes;
    void refreshProcessList();
};
