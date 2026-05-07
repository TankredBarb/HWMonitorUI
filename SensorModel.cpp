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

    switch (role) {
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
    case ObjectRole: {
        QVariantMap map;
        map.insert("id", item.uniqueId);
        map.insert("name", item.displayName);
        map.insert("value", item.base.value);
        map.insert("unit", item.base.unit);
        map.insert("type", item.base.type);
        map.insert("deviceId", item.base.deviceId);
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
    return roles;
}

void SensorModel::updateData(const QList<SensorData> &newSensors, SensorNameManager *nameManager)
{
    // If model is empty, just fill it
    if (m_sensors.isEmpty())
    {
        beginResetModel();
        for (const auto &s : newSensors)
        {
            InternalSensorData item;
            item.base = s;
            item.uniqueId = s.deviceId + "::" + s.sensorName;
            item.displayName = nameManager ? nameManager->getDisplayName(item.uniqueId, s.sensorName) : s.sensorName;
            m_sensors.append(item);
        }
        endResetModel();
        return;
    }

    // Smart update: keep items and update values
    // We assume the set of sensors is relatively stable.
    // If a sensor is added or removed, we will handle it via beginInsertRows/beginRemoveRows
    // to keep delegates alive.

    // 1. Map current sensors for quick lookup
    QHash<QString, int> currentIdMap;
    for (int i = 0; i < m_sensors.size(); ++i)
    {
        currentIdMap.insert(m_sensors[i].uniqueId, i);
    }

    // 2. Prepare new list and identify changes
    QList<InternalSensorData> nextSensors;
    QSet<QString> processedIds;

    bool structureChanged = false;

    for (const auto &s : newSensors) {
        QString uid = s.deviceId + "::" + s.sensorName;
        InternalSensorData item;
        item.base = s;
        item.uniqueId = uid;
        item.displayName = nameManager ? nameManager->getDisplayName(uid, s.sensorName) : s.sensorName;
        nextSensors.append(item);
        processedIds.insert(uid);

        if (!currentIdMap.contains(uid)) structureChanged = true;
    }

    if (m_sensors.size() != nextSensors.size()) structureChanged = true;

    if (structureChanged)
    {
        // If structure changed, for now we reset, but we could do fine-grained updates.
        // Usually HW sensors don't change their set during runtime unless hardware is hot-plugged.
        // Let's check if it's just a shuffle.
        beginResetModel();
        m_sensors = nextSensors;
        endResetModel();
    }
    else
    {
        // Same set of sensors, maybe different order or just values
        for (int i = 0; i < nextSensors.size(); ++i)
        {
            const auto &newS = nextSensors[i];
            int oldIndex = currentIdMap.value(newS.uniqueId, -1);
            
            if (oldIndex != -1) {
                // Update existing item at oldIndex
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

                if (changed)
                {
                    roles << ObjectRole;
                    emit dataChanged(index(oldIndex), index(oldIndex), roles);
                }
            }
        }
    }
}
