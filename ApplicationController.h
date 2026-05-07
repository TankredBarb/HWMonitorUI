#pragma once

#include <QObject>
#include <QtQml/QQmlApplicationEngine>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlContext>
#include "iSensorProvider.h"
#include "SensorNameManager.h"

class ApplicationController : public QObject
{
    Q_OBJECT

public:
    explicit ApplicationController(QObject *parent = nullptr);
    ~ApplicationController();

    bool initialize();
    int exec();

private slots:
    void onDataReady(const HardwareInfo &hw, const QList<SensorData> &sensors);
    void onError(const QString &error);
    void onConnectionStateChanged(ISensorProvider::ConnectionState state);

private:
    QVariantMap sensorToMap(const SensorData &s);
    void updateQmlData(const HardwareInfo &hw, const QList<SensorData> &sensors);
    QString getConnectionStatusText(ISensorProvider::ConnectionState state);

    QQmlApplicationEngine m_engine;
    SensorNameManager m_nameManager;
    ISensorProvider *m_provider;
    QTimer *m_timer;
    QObject *m_rootObject;
};

