#include "ApplicationController.h"
#include <QGuiApplication>
#include <QTimer>
#include <QDebug>
#include <QIcon>

#ifdef Q_OS_WIN
    #include "lhmClient.h"
#elif defined(Q_OS_LINUX)
    #include "linuxSysfsProvider.h"
#endif

ApplicationController::ApplicationController(QObject *parent)
    : QObject(parent)
    , m_provider(nullptr)
    , m_timer(nullptr)
    , m_rootObject(nullptr)
{
}

ApplicationController::~ApplicationController()
{
    if (m_provider)
    {
        m_provider->deleteLater();
    }
}

bool ApplicationController::initialize()
{
    QGuiApplication::setApplicationName("QtHwMonitor");
    QGuiApplication::setWindowIcon(QIcon(":/hwmon.png"));

    m_engine.rootContext()->setContextProperty("sensorNameManager", &m_nameManager);

    // Create platform-specific provider
#ifdef Q_OS_WIN
    m_provider = new LhmClient(this);
#elif defined(Q_OS_LINUX)
    m_provider = new LinuxSysfsProvider(this);
#endif

    if (!m_provider)
    {
        qFatal("Unsupported platform");
        return false;
    }

    m_engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (m_engine.rootObjects().isEmpty())
    {
        return false;
    }

    m_rootObject = m_engine.rootObjects().first();

    // Connect signals
    connect(m_provider, &ISensorProvider::dataReady, this, &ApplicationController::onDataReady);
    connect(m_provider, &ISensorProvider::error, this, &ApplicationController::onError);
    connect(m_provider, &ISensorProvider::connectionStateChanged, this, &ApplicationController::onConnectionStateChanged);
    connect(m_rootObject, SIGNAL(reconnectClicked()), m_provider, SLOT(reconnect()));

    // Setup timer for periodic updates
    m_timer = new QTimer(this);
    m_timer->setInterval(2000);
    connect(m_timer, &QTimer::timeout, m_provider, &ISensorProvider::fetchData);

    return true;
}

int ApplicationController::exec()
{
    // Initial data fetch
    if (m_provider)
    {
        m_provider->fetchData();
    }

    return QGuiApplication::instance()->exec();
}

QVariantMap ApplicationController::sensorToMap(const SensorData &s)
{
    QVariantMap map;
    QString uniqueId = s.deviceId + "::" + s.sensorName;

    map.insert("id", uniqueId);
    map.insert("name", s.sensorName);
    map.insert("value", s.value);
    map.insert("unit", s.unit);
    map.insert("type", s.type);
    map.insert("deviceId", s.deviceId);
    return map;
}

void ApplicationController::updateQmlData(const HardwareInfo &hw, const QList<SensorData> &sensors)
{
    if (!m_rootObject)
        return;

    // 1. Update Hardware Info
    QVariantMap hwMap;
    hwMap.insert("cpu", hw.cpuModel);
    hwMap.insert("gpu", hw.gpuModel);
    hwMap.insert("mb", hw.motherboardModel);
    m_rootObject->setProperty("hardwareInfo", hwMap);

    // 2. Update Sensors List
    QVariantList sensorList;
    for (const auto &s : sensors)
    {
        QVariantMap map = sensorToMap(s);
        QString uniqueId = s.deviceId + "::" + s.sensorName;
        QString displayName = m_nameManager.getDisplayName(uniqueId, s.sensorName);
        map.insert("name", displayName);
        sensorList.append(map);
    }
    m_rootObject->setProperty("sensors", sensorList);
}

void ApplicationController::onDataReady(const HardwareInfo &hw, const QList<SensorData> &sensors)
{
    updateQmlData(hw, sensors);
}

void ApplicationController::onError(const QString &error)
{
    qCritical() << "[ERROR]" << error;
}

QString ApplicationController::getConnectionStatusText(ISensorProvider::ConnectionState state)
{
    switch (state)
    {
        case ISensorProvider::ConnectionState::Disconnected:
            return "Disconnected";
        case ISensorProvider::ConnectionState::Connecting:
            return "Connecting...";
        case ISensorProvider::ConnectionState::Error:
            return "Connection Error";
        case ISensorProvider::ConnectionState::Connected:
            return "Connected";
    }
    return "Unknown";
}

void ApplicationController::onConnectionStateChanged(ISensorProvider::ConnectionState state)
{
    if (!m_rootObject)
        return;

    m_rootObject->setProperty("connectionState", static_cast<int>(state));

    QString statusText = getConnectionStatusText(state);
    m_rootObject->setProperty("connectionStatusText", statusText);

    // Control timer based on connection state
    if (state == ISensorProvider::ConnectionState::Connected)
    {
        m_timer->start();
    }
    else
    {
        m_timer->stop();
    }
}