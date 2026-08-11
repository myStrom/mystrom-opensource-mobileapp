// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_device.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoredDeviceAdapter extends TypeAdapter<StoredDevice> {
  @override
  final int typeId = 0;

  @override
  StoredDevice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredDevice(
      mac: fields[0] as String,
      name: fields[1] as String,
      typeCode: fields[2] as int,
      lastKnownIp: fields[3] as String?,
      lastSeen: fields[4] as DateTime?,
      customName: fields[5] as String?,
      addedAt: fields[6] as DateTime,
      room: fields[7] as String?,
      token: fields[8] as String?,
      colorValue: fields[9] as int?,
      favorite: fields[10] as bool? ?? false,
      lockable: fields[11] as bool? ?? false,
      totalEnergyWs: fields[12] as double? ?? 0,
      bootId: fields[13] as String?,
      bootEnergyWs: fields[14] as double? ?? 0,
      temperatureOffset: fields[15] as double? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, StoredDevice obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.mac)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.typeCode)
      ..writeByte(3)
      ..write(obj.lastKnownIp)
      ..writeByte(4)
      ..write(obj.lastSeen)
      ..writeByte(5)
      ..write(obj.customName)
      ..writeByte(6)
      ..write(obj.addedAt)
      ..writeByte(7)
      ..write(obj.room)
      ..writeByte(8)
      ..write(obj.token)
      ..writeByte(9)
      ..write(obj.colorValue)
      ..writeByte(10)
      ..write(obj.favorite)
      ..writeByte(11)
      ..write(obj.lockable)
      ..writeByte(12)
      ..write(obj.totalEnergyWs)
      ..writeByte(13)
      ..write(obj.bootId)
      ..writeByte(14)
      ..write(obj.bootEnergyWs)
      ..writeByte(15)
      ..write(obj.temperatureOffset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredDeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
