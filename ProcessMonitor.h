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

struct PerPidInfo
{
    uint32_t pid;
    double cpuUsage;
    double workingSetMb;
    double privateBytesMb;
};

struct ProcessInfo
{
    uint32_t pid;
    QString name;
    QString exePath;
    double cpuUsage;
    double workingSetMb;
    double privateBytesMb;
    QList<PerPidInfo> multiPids;
};

class ProcessMonitor : public QObject
{
    Q_OBJECT
public:
    explicit ProcessMonitor(QObject *parent = nullptr);
    
    QVariantList getCpuProcesses();
    QVariantList getMemoryProcesses();
    QMap<QString, QString> getExePathMap() const;
    double getTotalRamMb();
    double getUsedRamMb();
    
    double getTotalCpuUsage() const { return m_totalCpuUsage; }
    void update();

private:
#ifdef Q_OS_WIN
    struct ProcessTimeInfo
    {
        ULONGLONG lastTime;
        ULONGLONG lastSystemTime;
    };
    QMap<uint32_t, ProcessTimeInfo> m_processTimeMap;
    ULONGLONG m_lastSystemTime = 0;
    ULONGLONG m_lastIdleTime = 0;
    double m_totalCpuUsage = 0.0;
#endif

    QList<ProcessInfo> m_processes;
    void refreshProcessList();
};
