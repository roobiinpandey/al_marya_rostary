// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_address.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAddressAdapter extends TypeAdapter<UserAddress> {
  @override
  final int typeId = 0;

  @override
  UserAddress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAddress(
      id: fields[0] as String?,
      label: fields[1] as String,
      street: fields[2] as String,
      building: fields[3] as String,
      apartment: fields[4] as String,
      directions: fields[5] as String,
      nickname: fields[6] as String,
      receiverName: fields[7] as String,
      phoneNumber: fields[8] as String,
      latitude: fields[9] as double,
      longitude: fields[10] as double,
      isDefault: fields[11] as bool,
      createdAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserAddress obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.street)
      ..writeByte(3)
      ..write(obj.building)
      ..writeByte(4)
      ..write(obj.apartment)
      ..writeByte(5)
      ..write(obj.directions)
      ..writeByte(6)
      ..write(obj.nickname)
      ..writeByte(7)
      ..write(obj.receiverName)
      ..writeByte(8)
      ..write(obj.phoneNumber)
      ..writeByte(9)
      ..write(obj.latitude)
      ..writeByte(10)
      ..write(obj.longitude)
      ..writeByte(11)
      ..write(obj.isDefault)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
