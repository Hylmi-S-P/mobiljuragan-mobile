// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_dao.dart';

// ignore_for_file: type=lint
mixin _$BookingDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookingsTable get bookings => attachedDatabase.bookings;
  BookingDaoManager get managers => BookingDaoManager(this);
}

class BookingDaoManager {
  final _$BookingDaoMixin _db;
  BookingDaoManager(this._db);
  $$BookingsTableTableManager get bookings =>
      $$BookingsTableTableManager(_db.attachedDatabase, _db.bookings);
}
