#pragma once

#include <QObject>
#include <QtQml/QQmlApplicationEngine>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlContext>
#include <QTimer>
#include "iSensorProvider.h"
#include "SensorNameManager.h"
#include "SensorModel.h"
#include "ProcessMonitor.h"

class ApplicationController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString rawJson READ rawJson NOTIFY rawJsonChanged)
    Q_PROPERTY(QVariantList cpuProcesses READ cpuProcesses NOTIFY cpuProcessesChanged)
    Q_PROPERTY(QVariantList memoryProcesses READ memoryProcesses NOTIFY memoryProcessesChanged)
    Q_PROPERTY(double totalRamMb READ totalRamMb NOTIFY memoryProcessesChanged)
    Q_PROPERTY(QString cpuProcessError READ cpuProcessError NOTIFY cpuProcessErrorChanged)

public:
    explicit ApplicationController(QObject *parent = nullptr);
    ~ApplicationController();

    bool initialize();
    int exec();

    QString rawJson() const { return m_rawJson; }
    QVariantList cpuProcesses() const { return m_cpuProcesses; }
    QVariantList memoryProcesses() const { return m_memoryProcesses; }
    double totalRamMb() { return m_processMonitor.getTotalRamMb(); }
    QString cpuProcessError() const { return m_cpuProcessError; }

    Q_INVOKABLE void refreshCpuProcesses();
    Q_INVOKABLE void refreshMemoryProcesses();

signals:
    void rawJsonChanged();
    void cpuProcessesChanged();
    void memoryProcessesChanged();
    void cpuProcessErrorChanged();

private slots:
    void onDataReady(const HardwareInfo &hw, const QList<SensorData> &sensors);
    void onRawDataReceived(const QString &json);
    void onError(const QString &error);
    void onConnectionStateChanged(ISensorProvider::ConnectionState state);
    void updateProcesses();

private:
    void updateQmlData(const HardwareInfo &hw, const QList<SensorData> &sensors);
    QString getConnectionStatusText(ISensorProvider::ConnectionState state);

    QQmlApplicationEngine m_engine;
    SensorNameManager m_nameManager;
    SensorModel m_sensorModel;
    ISensorProvider *m_provider;
    QTimer *m_timer;
    QTimer *m_processTimer;
    ProcessMonitor m_processMonitor;
    QObject *m_rootObject;
    QString m_rawJson;
    QVariantList m_cpuProcesses;
    QVariantList m_memoryProcesses;
    QString m_cpuProcessError;
};

