#pragma once

#include <QAbstractListModel>
#include <QHash>
#include <QByteArray>
#include "iSensorProvider.h"
#include "SensorNameManager.h"

class SensorModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum SensorRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ValueRole,
        UnitRole,
        TypeRole,
        DeviceIdRole,
        ObjectRole
    };

    explicit SensorModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void updateData(const QList<SensorData> &newSensors, SensorNameManager *nameManager);

private:
    struct InternalSensorData {
        SensorData base;
        QString displayName;
        QString uniqueId;
    };

    QList<InternalSensorData> m_sensors;
};
