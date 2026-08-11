// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SceneAdapter extends TypeAdapter<Scene> {
  @override
  final int typeId = 1;

  @override
  Scene read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Scene(
      id: fields[0] as String,
      name: fields[1] as String,
      iconCode: fields[2] as int,
      colorValue: fields[3] as int,
      actions: (fields[4] as List?)?.cast<SceneAction>(),
    );
  }

  @override
  void write(BinaryWriter writer, Scene obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconCode)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.actions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SceneActionAdapter extends TypeAdapter<SceneAction> {
  @override
  final int typeId = 2;

  @override
  SceneAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SceneAction(
      deviceMac: fields[0] as String,
      deviceName: fields[1] as String,
      deviceTypeCode: fields[2] as int,
      action: fields[3] as String,
      timerMode: fields[4] as String?,
      timerSeconds: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SceneAction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.deviceMac)
      ..writeByte(1)
      ..write(obj.deviceName)
      ..writeByte(2)
      ..write(obj.deviceTypeCode)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.timerMode)
      ..writeByte(5)
      ..write(obj.timerSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
