#include "SensorModel.h"
#include <QDebug>

SensorModel::SensorModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SensorModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_sensors.count();
}

QVariant SensorModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_sensors.count())
        return QVariant();

    const auto &item = m_sensors.at(index.row());

    switch (role)
    {
    case IdRole:
        return item.uniqueId;
    case NameRole:
        return item.displayName;
    case ValueRole:
        return item.base.value;
    case UnitRole:
        return item.base.unit;
    case TypeRole:
        return item.base.type;
    case DeviceIdRole:
        return item.base.deviceId;
    case ColorRole:
        return item.color;
    case BoldRole:
        return item.isBold;
    case ObjectRole:
    {
        QVariantMap map;
        map.insert("id", item.uniqueId);
        map.insert("name", item.displayName);
        map.insert("value", item.base.value);
        map.insert("unit", item.base.unit);
        map.insert("type", item.base.type);
        map.insert("deviceId", item.base.deviceId);
        map.insert("color", item.color);
        map.insert("isBold", item.isBold);
        return map;
    }
    case Qt::DisplayRole:
        return item.displayName;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> SensorModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[ValueRole] = "value";
    roles[UnitRole] = "unit";
    roles[TypeRole] = "type";
    roles[DeviceIdRole] = "deviceId";
    roles[ObjectRole] = "sensorData";
    roles[ColorRole] = "color";
    roles[BoldRole] = "isBold";
    return roles;
}

void SensorModel::updateData(const QList<SensorData> &newSensors, SensorNameManager *nameManager)
{
    if (m_sensors.isEmpty())
    {
        beginResetModel();
        for (const auto &s : newSensors)
        {
            InternalSensorData item;
            item.base = s;
            item.uniqueId = s.deviceId + "::" + s.sensorName;
            item.displayName = nameManager ? nameManager->getDisplayName(item.uniqueId, s.sensorName) : s.sensorName;
            item.color = nameManager ? nameManager->getSensorColor(item.uniqueId) : "#1A1A1A";
            item.isBold = nameManager ? nameManager->getSensorBold(item.uniqueId) : false;
            m_sensors.append(item);
        }
        endResetModel();
        return;
    }

    QHash<QString, int> currentIdMap;
    for (int i = 0; i < m_sensors.size(); ++i)
    {
        currentIdMap.insert(m_sensors[i].uniqueId, i);
    }

    QList<InternalSensorData> nextSensors;
    bool structureChanged = false;

    for (const auto &s : newSensors)
    {
        QString uid = s.deviceId + "::" + s.sensorName;
        InternalSensorData item;
        item.base = s;
        item.uniqueId = uid;
        item.displayName = nameManager ? nameManager->getDisplayName(uid, s.sensorName) : s.sensorName;
        item.color = nameManager ? nameManager->getSensorColor(uid) : "#1A1A1A";
        item.isBold = nameManager ? nameManager->getSensorBold(uid) : false;
        nextSensors.append(item);

        if (!currentIdMap.contains(uid)) structureChanged = true;
    }

    if (m_sensors.size() != nextSensors.size()) structureChanged = true;

    if (structureChanged)
    {
        beginResetModel();
        m_sensors = nextSensors;
        endResetModel();
    }
    else
    {
        for (int i = 0; i < nextSensors.size(); ++i)
        {
            const auto &newS = nextSensors[i];
            int oldIndex = currentIdMap.value(newS.uniqueId, -1);
            
            if (oldIndex != -1)
            {
                bool changed = false;
                QVector<int> roles;

                if (qAbs(m_sensors[oldIndex].base.value - newS.base.value) > 0.01)
                {
                    m_sensors[oldIndex].base.value = newS.base.value;
                    roles << ValueRole;
                    changed = true;
                }
                if (m_sensors[oldIndex].displayName != newS.displayName)
                {
                    m_sensors[oldIndex].displayName = newS.displayName;
                    roles << NameRole;
                    changed = true;
                }
                if (m_sensors[oldIndex].color != newS.color)
                {
                    m_sensors[oldIndex].color = newS.color;
                    roles << ColorRole;
                    changed = true;
                }
                if (m_sensors[oldIndex].isBold != newS.isBold)
                {
                    m_sensors[oldIndex].isBold = newS.isBold;
                    roles << BoldRole;
                    changed = true;
                }

                if (changed)
                {
                    roles << ObjectRole;
                    emit dataChanged(index(oldIndex), index(oldIndex), roles);
                }
            }
        }
    }
}
