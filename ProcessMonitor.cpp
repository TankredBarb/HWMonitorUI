#include "ProcessMonitor.h"
#include <QDebug>
#include <QtAlgorithms>

#ifdef Q_OS_WIN
#include <windows.h>
#include <tlhelp32.h>
#include <psapi.h>

static ULONGLONG FileTimeToULL(const FILETIME& ft) {
    ULARGE_INTEGER ui;
    ui.LowPart = ft.dwLowDateTime;
    ui.HighPart = ft.dwHighDateTime;
    return ui.QuadPart;
}
#endif

ProcessMonitor::ProcessMonitor(QObject *parent) : QObject(parent) {
}

void ProcessMonitor::update() {
    refreshProcessList();
}

QVariantList ProcessMonitor::getCpuProcesses() {
    QMap<QString, ProcessInfo> grouped;
    for (const auto& p : m_processes) {
        if (grouped.contains(p.name)) {
            grouped[p.name].cpuUsage += p.cpuUsage;
            grouped[p.name].workingSetMb += p.workingSetMb;
            grouped[p.name].privateBytesMb += p.privateBytesMb;
            grouped[p.name].multiPids.append(p.pid);
        } else {
            ProcessInfo info = p;
            info.multiPids = {p.pid};
            grouped.insert(p.name, info);
        }
    }

    QList<ProcessInfo> sorted = grouped.values();
    std::sort(sorted.begin(), sorted.end(), [](const ProcessInfo& a, const ProcessInfo& b) {
        return a.cpuUsage > b.cpuUsage;
    });

    QVariantList list;
    for (int i = 0; i < qMin(sorted.size(), 50); ++i) {
        const auto& p = sorted[i];
        if (p.cpuUsage < 0.1 && i > 15) break;
        QVariantMap map;
        if (p.multiPids.size() > 1) {
            map["id"] = QString("%1... (%2)").arg(p.multiPids[0]).arg(p.multiPids.size());
        } else {
            map["id"] = QString::number(p.pid);
        }
        map["name"] = p.name;
        map["cpu"] = p.cpuUsage;
        map["wsMb"] = p.workingSetMb;
        map["pmMb"] = p.privateBytesMb;
        list.append(map);
    }
    return list;
}

QVariantList ProcessMonitor::getMemoryProcesses() {
    QMap<QString, ProcessInfo> grouped;
    for (const auto& p : m_processes) {
        if (grouped.contains(p.name)) {
            grouped[p.name].cpuUsage += p.cpuUsage;
            grouped[p.name].workingSetMb += p.workingSetMb;
            grouped[p.name].privateBytesMb += p.privateBytesMb;
            grouped[p.name].multiPids.append(p.pid);
        } else {
            ProcessInfo info = p;
            info.multiPids = {p.pid};
            grouped.insert(p.name, info);
        }
    }

    QList<ProcessInfo> sorted = grouped.values();
    std::sort(sorted.begin(), sorted.end(), [](const ProcessInfo& a, const ProcessInfo& b) {
        return a.workingSetMb > b.workingSetMb;
    });

    QVariantList list;
    for (int i = 0; i < qMin(sorted.size(), 50); ++i) {
        const auto& p = sorted[i];
        QVariantMap map;
        if (p.multiPids.size() > 1) {
            map["id"] = QString("%1... (%2)").arg(p.multiPids[0]).arg(p.multiPids.size());
        } else {
            map["id"] = QString::number(p.pid);
        }
        map["name"] = p.name;
        map["cpu"] = p.cpuUsage;
        map["wsMb"] = p.workingSetMb;
        map["pmMb"] = p.privateBytesMb;
        list.append(map);
    }
    return list;
}

double ProcessMonitor::getTotalRamMb() {
#ifdef Q_OS_WIN
    MEMORYSTATUSEX memInfo;
    memInfo.dwLength = sizeof(MEMORYSTATUSEX);
    if (GlobalMemoryStatusEx(&memInfo)) {
        return memInfo.ullTotalPhys / (1024.0 * 1024.0);
    }
#endif
    return 0;
}

void ProcessMonitor::refreshProcessList() {
#ifdef Q_OS_WIN
    HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnapshot == INVALID_HANDLE_VALUE) return;

    PROCESSENTRY32W pe;
    pe.dwSize = sizeof(pe);

    if (!Process32FirstW(hSnapshot, &pe)) {
        CloseHandle(hSnapshot);
        return;
    }

    FILETIME sysIdle, sysKernel, sysUser;
    if (!GetSystemTimes(&sysIdle, &sysKernel, &sysUser)) {
        CloseHandle(hSnapshot);
        return;
    }
    ULONGLONG currentSystemTime = FileTimeToULL(sysIdle) + FileTimeToULL(sysUser);
    ULONGLONG systemDelta = currentSystemTime - m_lastSystemTime;
    
    QList<ProcessInfo> newProcesses;
    QMap<uint32_t, ProcessTimeInfo> newTimeMap;

    do {
        uint32_t pid = pe.th32ProcessID;
        if (pid == 0) continue; // Idle process

        HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid);
        if (hProcess) {
            FILETIME createTime, exitTime, kernelTime, userTime;
            if (GetProcessTimes(hProcess, &createTime, &exitTime, &kernelTime, &userTime)) {
                ULONGLONG currentProcessTime = FileTimeToULL(kernelTime) + FileTimeToULL(userTime);
                
                double cpuUsage = 0.0;
                if (m_processTimeMap.contains(pid) && systemDelta > 0) {
                    ULONGLONG processDelta = currentProcessTime - m_processTimeMap[pid].lastTime;
                    cpuUsage = (100.0 * processDelta) / systemDelta;
                }
                
                newTimeMap[pid] = {currentProcessTime, currentSystemTime};

                PROCESS_MEMORY_COUNTERS_EX pmc;
                double wsMb = 0, privMb = 0;
                if (GetProcessMemoryInfo(hProcess, (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) {
                    wsMb = pmc.WorkingSetSize / (1024.0 * 1024.0);
                    privMb = pmc.PrivateUsage / (1024.0 * 1024.0);
                }

                ProcessInfo info;
                info.pid = pid;
                info.name = QString::fromWCharArray(pe.szExeFile);
                info.cpuUsage = cpuUsage;
                info.workingSetMb = wsMb;
                info.privateBytesMb = privMb;
                newProcesses.append(info);
            }
            CloseHandle(hProcess);
        }
    } while (Process32NextW(hSnapshot, &pe));

    CloseHandle(hSnapshot);
    m_processes = newProcesses;
    m_processTimeMap = newTimeMap;
    m_lastSystemTime = currentSystemTime;
#endif
}
