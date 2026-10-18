// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plateNumberMeta = const VerificationMeta(
    'plateNumber',
  );
  @override
  late final GeneratedColumn<String> plateNumber = GeneratedColumn<String>(
    'plate_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatCapacityMeta = const VerificationMeta(
    'seatCapacity',
  );
  @override
  late final GeneratedColumn<String> seatCapacity = GeneratedColumn<String>(
    'seat_capacity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transmissionMeta = const VerificationMeta(
    'transmission',
  );
  @override
  late final GeneratedColumn<String> transmission = GeneratedColumn<String>(
    'transmission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyTypeMeta = const VerificationMeta(
    'bodyType',
  );
  @override
  late final GeneratedColumn<String> bodyType = GeneratedColumn<String>(
    'body_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availabilityTagMeta = const VerificationMeta(
    'availabilityTag',
  );
  @override
  late final GeneratedColumn<String> availabilityTag = GeneratedColumn<String>(
    'availability_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPopularMeta = const VerificationMeta(
    'isPopular',
  );
  @override
  late final GeneratedColumn<bool> isPopular = GeneratedColumn<bool>(
    'is_popular',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_popular" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pricePerDayMeta = const VerificationMeta(
    'pricePerDay',
  );
  @override
  late final GeneratedColumn<int> pricePerDay = GeneratedColumn<int>(
    'price_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heroImageUrlMeta = const VerificationMeta(
    'heroImageUrl',
  );
  @override
  late final GeneratedColumn<String> heroImageUrl = GeneratedColumn<String>(
    'hero_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailImageUrlMeta = const VerificationMeta(
    'detailImageUrl',
  );
  @override
  late final GeneratedColumn<String> detailImageUrl = GeneratedColumn<String>(
    'detail_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFetchedMeta = const VerificationMeta(
    'lastFetched',
  );
  @override
  late final GeneratedColumn<int> lastFetched = GeneratedColumn<int>(
    'last_fetched',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    plateNumber,
    category,
    seatCapacity,
    transmission,
    bodyType,
    condition,
    availabilityTag,
    isPopular,
    pricePerDay,
    imageUrl,
    heroImageUrl,
    detailImageUrl,
    isFavorite,
    lastFetched,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('plate_number')) {
      context.handle(
        _plateNumberMeta,
        plateNumber.isAcceptableOrUnknown(
          data['plate_number']!,
          _plateNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plateNumberMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('seat_capacity')) {
      context.handle(
        _seatCapacityMeta,
        seatCapacity.isAcceptableOrUnknown(
          data['seat_capacity']!,
          _seatCapacityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seatCapacityMeta);
    }
    if (data.containsKey('transmission')) {
      context.handle(
        _transmissionMeta,
        transmission.isAcceptableOrUnknown(
          data['transmission']!,
          _transmissionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transmissionMeta);
    }
    if (data.containsKey('body_type')) {
      context.handle(
        _bodyTypeMeta,
        bodyType.isAcceptableOrUnknown(data['body_type']!, _bodyTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyTypeMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    } else if (isInserting) {
      context.missing(_conditionMeta);
    }
    if (data.containsKey('availability_tag')) {
      context.handle(
        _availabilityTagMeta,
        availabilityTag.isAcceptableOrUnknown(
          data['availability_tag']!,
          _availabilityTagMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityTagMeta);
    }
    if (data.containsKey('is_popular')) {
      context.handle(
        _isPopularMeta,
        isPopular.isAcceptableOrUnknown(data['is_popular']!, _isPopularMeta),
      );
    }
    if (data.containsKey('price_per_day')) {
      context.handle(
        _pricePerDayMeta,
        pricePerDay.isAcceptableOrUnknown(
          data['price_per_day']!,
          _pricePerDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerDayMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_imageUrlMeta);
    }
    if (data.containsKey('hero_image_url')) {
      context.handle(
        _heroImageUrlMeta,
        heroImageUrl.isAcceptableOrUnknown(
          data['hero_image_url']!,
          _heroImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('detail_image_url')) {
      context.handle(
        _detailImageUrlMeta,
        detailImageUrl.isAcceptableOrUnknown(
          data['detail_image_url']!,
          _detailImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_fetched')) {
      context.handle(
        _lastFetchedMeta,
        lastFetched.isAcceptableOrUnknown(
          data['last_fetched']!,
          _lastFetchedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFetchedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      plateNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plate_number'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      seatCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seat_capacity'],
      )!,
      transmission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transmission'],
      )!,
      bodyType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_type'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      availabilityTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability_tag'],
      )!,
      isPopular: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_popular'],
      )!,
      pricePerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_day'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      heroImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hero_image_url'],
      ),
      detailImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_image_url'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastFetched: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fetched'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  /// Pengenal unik armada (contoh: 'avanza-g-putih' atau UUID backend)
  final String id;

  /// Nama lengkap kendaraan (contoh: 'AVANZA G PUTIH')
  final String name;

  /// Nomor plat kendaraan (contoh: 'PS1692B')
  final String plateNumber;

  /// Kategori kendaraan: 'MPV', 'SUV', 'Pickup'
  final String category;

  /// Kapasitas kursi penumpang (contoh: '7 Penumpang')
  final String seatCapacity;

  /// Tipe transmisi: 'Manual' atau 'Matic'
  final String transmission;

  /// Tipe bodi armada (contoh: 'MPV Keluarga', 'SUV Tangguh')
  final String bodyType;

  /// Kondisi armada (contoh: 'Siap Pakai', 'AC Dingin')
  final String condition;

  /// Label ketersediaan (contoh: 'Tersedia • Lepas Kunci')
  final String availabilityTag;

  /// Penanda armada paling diminati
  final bool isPopular;

  /// Tarif sewa harian dalam Rupiah
  final int pricePerDay;

  /// URL atau aset gambar kartu
  final String imageUrl;

  /// Gambar hero layar detail
  final String? heroImageUrl;

  /// Gambar spesifikasi layar detail
  final String? detailImageUrl;

  /// Status penanda kendaraan favorit pengguna (reaktif & offline)
  final bool isFavorite;

  /// Atribut penanda cache wajib: Waktu terakhir data disinkronkan dari server (UTC Milliseconds)
  final int lastFetched;

  /// Waktu pembaruan di server (UTC Milliseconds)
  final int? updatedAt;
  const Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.category,
    required this.seatCapacity,
    required this.transmission,
    required this.bodyType,
    required this.condition,
    required this.availabilityTag,
    required this.isPopular,
    required this.pricePerDay,
    required this.imageUrl,
    this.heroImageUrl,
    this.detailImageUrl,
    required this.isFavorite,
    required this.lastFetched,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['plate_number'] = Variable<String>(plateNumber);
    map['category'] = Variable<String>(category);
    map['seat_capacity'] = Variable<String>(seatCapacity);
    map['transmission'] = Variable<String>(transmission);
    map['body_type'] = Variable<String>(bodyType);
    map['condition'] = Variable<String>(condition);
    map['availability_tag'] = Variable<String>(availabilityTag);
    map['is_popular'] = Variable<bool>(isPopular);
    map['price_per_day'] = Variable<int>(pricePerDay);
    map['image_url'] = Variable<String>(imageUrl);
    if (!nullToAbsent || heroImageUrl != null) {
      map['hero_image_url'] = Variable<String>(heroImageUrl);
    }
    if (!nullToAbsent || detailImageUrl != null) {
      map['detail_image_url'] = Variable<String>(detailImageUrl);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['last_fetched'] = Variable<int>(lastFetched);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      name: Value(name),
      plateNumber: Value(plateNumber),
      category: Value(category),
      seatCapacity: Value(seatCapacity),
      transmission: Value(transmission),
      bodyType: Value(bodyType),
      condition: Value(condition),
      availabilityTag: Value(availabilityTag),
      isPopular: Value(isPopular),
      pricePerDay: Value(pricePerDay),
      imageUrl: Value(imageUrl),
      heroImageUrl: heroImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(heroImageUrl),
      detailImageUrl: detailImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(detailImageUrl),
      isFavorite: Value(isFavorite),
      lastFetched: Value(lastFetched),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      plateNumber: serializer.fromJson<String>(json['plateNumber']),
      category: serializer.fromJson<String>(json['category']),
      seatCapacity: serializer.fromJson<String>(json['seatCapacity']),
      transmission: serializer.fromJson<String>(json['transmission']),
      bodyType: serializer.fromJson<String>(json['bodyType']),
      condition: serializer.fromJson<String>(json['condition']),
      availabilityTag: serializer.fromJson<String>(json['availabilityTag']),
      isPopular: serializer.fromJson<bool>(json['isPopular']),
      pricePerDay: serializer.fromJson<int>(json['pricePerDay']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      heroImageUrl: serializer.fromJson<String?>(json['heroImageUrl']),
      detailImageUrl: serializer.fromJson<String?>(json['detailImageUrl']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastFetched: serializer.fromJson<int>(json['lastFetched']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'plateNumber': serializer.toJson<String>(plateNumber),
      'category': serializer.toJson<String>(category),
      'seatCapacity': serializer.toJson<String>(seatCapacity),
      'transmission': serializer.toJson<String>(transmission),
      'bodyType': serializer.toJson<String>(bodyType),
      'condition': serializer.toJson<String>(condition),
      'availabilityTag': serializer.toJson<String>(availabilityTag),
      'isPopular': serializer.toJson<bool>(isPopular),
      'pricePerDay': serializer.toJson<int>(pricePerDay),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'heroImageUrl': serializer.toJson<String?>(heroImageUrl),
      'detailImageUrl': serializer.toJson<String?>(detailImageUrl),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastFetched': serializer.toJson<int>(lastFetched),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  Vehicle copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? category,
    String? seatCapacity,
    String? transmission,
    String? bodyType,
    String? condition,
    String? availabilityTag,
    bool? isPopular,
    int? pricePerDay,
    String? imageUrl,
    Value<String?> heroImageUrl = const Value.absent(),
    Value<String?> detailImageUrl = const Value.absent(),
    bool? isFavorite,
    int? lastFetched,
    Value<int?> updatedAt = const Value.absent(),
  }) => Vehicle(
    id: id ?? this.id,
    name: name ?? this.name,
    plateNumber: plateNumber ?? this.plateNumber,
    category: category ?? this.category,
    seatCapacity: seatCapacity ?? this.seatCapacity,
    transmission: transmission ?? this.transmission,
    bodyType: bodyType ?? this.bodyType,
    condition: condition ?? this.condition,
    availabilityTag: availabilityTag ?? this.availabilityTag,
    isPopular: isPopular ?? this.isPopular,
    pricePerDay: pricePerDay ?? this.pricePerDay,
    imageUrl: imageUrl ?? this.imageUrl,
    heroImageUrl: heroImageUrl.present ? heroImageUrl.value : this.heroImageUrl,
    detailImageUrl: detailImageUrl.present
        ? detailImageUrl.value
        : this.detailImageUrl,
    isFavorite: isFavorite ?? this.isFavorite,
    lastFetched: lastFetched ?? this.lastFetched,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      plateNumber: data.plateNumber.present
          ? data.plateNumber.value
          : this.plateNumber,
      category: data.category.present ? data.category.value : this.category,
      seatCapacity: data.seatCapacity.present
          ? data.seatCapacity.value
          : this.seatCapacity,
      transmission: data.transmission.present
          ? data.transmission.value
          : this.transmission,
      bodyType: data.bodyType.present ? data.bodyType.value : this.bodyType,
      condition: data.condition.present ? data.condition.value : this.condition,
      availabilityTag: data.availabilityTag.present
          ? data.availabilityTag.value
          : this.availabilityTag,
      isPopular: data.isPopular.present ? data.isPopular.value : this.isPopular,
      pricePerDay: data.pricePerDay.present
          ? data.pricePerDay.value
          : this.pricePerDay,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      heroImageUrl: data.heroImageUrl.present
          ? data.heroImageUrl.value
          : this.heroImageUrl,
      detailImageUrl: data.detailImageUrl.present
          ? data.detailImageUrl.value
          : this.detailImageUrl,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastFetched: data.lastFetched.present
          ? data.lastFetched.value
          : this.lastFetched,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('category: $category, ')
          ..write('seatCapacity: $seatCapacity, ')
          ..write('transmission: $transmission, ')
          ..write('bodyType: $bodyType, ')
          ..write('condition: $condition, ')
          ..write('availabilityTag: $availabilityTag, ')
          ..write('isPopular: $isPopular, ')
          ..write('pricePerDay: $pricePerDay, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('heroImageUrl: $heroImageUrl, ')
          ..write('detailImageUrl: $detailImageUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    plateNumber,
    category,
    seatCapacity,
    transmission,
    bodyType,
    condition,
    availabilityTag,
    isPopular,
    pricePerDay,
    imageUrl,
    heroImageUrl,
    detailImageUrl,
    isFavorite,
    lastFetched,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.id == this.id &&
          other.name == this.name &&
          other.plateNumber == this.plateNumber &&
          other.category == this.category &&
          other.seatCapacity == this.seatCapacity &&
          other.transmission == this.transmission &&
          other.bodyType == this.bodyType &&
          other.condition == this.condition &&
          other.availabilityTag == this.availabilityTag &&
          other.isPopular == this.isPopular &&
          other.pricePerDay == this.pricePerDay &&
          other.imageUrl == this.imageUrl &&
          other.heroImageUrl == this.heroImageUrl &&
          other.detailImageUrl == this.detailImageUrl &&
          other.isFavorite == this.isFavorite &&
          other.lastFetched == this.lastFetched &&
          other.updatedAt == this.updatedAt);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> plateNumber;
  final Value<String> category;
  final Value<String> seatCapacity;
  final Value<String> transmission;
  final Value<String> bodyType;
  final Value<String> condition;
  final Value<String> availabilityTag;
  final Value<bool> isPopular;
  final Value<int> pricePerDay;
  final Value<String> imageUrl;
  final Value<String?> heroImageUrl;
  final Value<String?> detailImageUrl;
  final Value<bool> isFavorite;
  final Value<int> lastFetched;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.category = const Value.absent(),
    this.seatCapacity = const Value.absent(),
    this.transmission = const Value.absent(),
    this.bodyType = const Value.absent(),
    this.condition = const Value.absent(),
    this.availabilityTag = const Value.absent(),
    this.isPopular = const Value.absent(),
    this.pricePerDay = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.heroImageUrl = const Value.absent(),
    this.detailImageUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    required String id,
    required String name,
    required String plateNumber,
    required String category,
    required String seatCapacity,
    required String transmission,
    required String bodyType,
    required String condition,
    required String availabilityTag,
    this.isPopular = const Value.absent(),
    required int pricePerDay,
    required String imageUrl,
    this.heroImageUrl = const Value.absent(),
    this.detailImageUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required int lastFetched,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       plateNumber = Value(plateNumber),
       category = Value(category),
       seatCapacity = Value(seatCapacity),
       transmission = Value(transmission),
       bodyType = Value(bodyType),
       condition = Value(condition),
       availabilityTag = Value(availabilityTag),
       pricePerDay = Value(pricePerDay),
       imageUrl = Value(imageUrl),
       lastFetched = Value(lastFetched);
  static Insertable<Vehicle> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? plateNumber,
    Expression<String>? category,
    Expression<String>? seatCapacity,
    Expression<String>? transmission,
    Expression<String>? bodyType,
    Expression<String>? condition,
    Expression<String>? availabilityTag,
    Expression<bool>? isPopular,
    Expression<int>? pricePerDay,
    Expression<String>? imageUrl,
    Expression<String>? heroImageUrl,
    Expression<String>? detailImageUrl,
    Expression<bool>? isFavorite,
    Expression<int>? lastFetched,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (category != null) 'category': category,
      if (seatCapacity != null) 'seat_capacity': seatCapacity,
      if (transmission != null) 'transmission': transmission,
      if (bodyType != null) 'body_type': bodyType,
      if (condition != null) 'condition': condition,
      if (availabilityTag != null) 'availability_tag': availabilityTag,
      if (isPopular != null) 'is_popular': isPopular,
      if (pricePerDay != null) 'price_per_day': pricePerDay,
      if (imageUrl != null) 'image_url': imageUrl,
      if (heroImageUrl != null) 'hero_image_url': heroImageUrl,
      if (detailImageUrl != null) 'detail_image_url': detailImageUrl,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastFetched != null) 'last_fetched': lastFetched,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? plateNumber,
    Value<String>? category,
    Value<String>? seatCapacity,
    Value<String>? transmission,
    Value<String>? bodyType,
    Value<String>? condition,
    Value<String>? availabilityTag,
    Value<bool>? isPopular,
    Value<int>? pricePerDay,
    Value<String>? imageUrl,
    Value<String?>? heroImageUrl,
    Value<String?>? detailImageUrl,
    Value<bool>? isFavorite,
    Value<int>? lastFetched,
    Value<int?>? updatedAt,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      category: category ?? this.category,
      seatCapacity: seatCapacity ?? this.seatCapacity,
      transmission: transmission ?? this.transmission,
      bodyType: bodyType ?? this.bodyType,
      condition: condition ?? this.condition,
      availabilityTag: availabilityTag ?? this.availabilityTag,
      isPopular: isPopular ?? this.isPopular,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      imageUrl: imageUrl ?? this.imageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      detailImageUrl: detailImageUrl ?? this.detailImageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      lastFetched: lastFetched ?? this.lastFetched,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (plateNumber.present) {
      map['plate_number'] = Variable<String>(plateNumber.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (seatCapacity.present) {
      map['seat_capacity'] = Variable<String>(seatCapacity.value);
    }
    if (transmission.present) {
      map['transmission'] = Variable<String>(transmission.value);
    }
    if (bodyType.present) {
      map['body_type'] = Variable<String>(bodyType.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (availabilityTag.present) {
      map['availability_tag'] = Variable<String>(availabilityTag.value);
    }
    if (isPopular.present) {
      map['is_popular'] = Variable<bool>(isPopular.value);
    }
    if (pricePerDay.present) {
      map['price_per_day'] = Variable<int>(pricePerDay.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (heroImageUrl.present) {
      map['hero_image_url'] = Variable<String>(heroImageUrl.value);
    }
    if (detailImageUrl.present) {
      map['detail_image_url'] = Variable<String>(detailImageUrl.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastFetched.present) {
      map['last_fetched'] = Variable<int>(lastFetched.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('category: $category, ')
          ..write('seatCapacity: $seatCapacity, ')
          ..write('transmission: $transmission, ')
          ..write('bodyType: $bodyType, ')
          ..write('condition: $condition, ')
          ..write('availabilityTag: $availabilityTag, ')
          ..write('isPopular: $isPopular, ')
          ..write('pricePerDay: $pricePerDay, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('heroImageUrl: $heroImageUrl, ')
          ..write('detailImageUrl: $detailImageUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookingsTable extends Bookings with TableInfo<$BookingsTable, Booking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<int> startDate = GeneratedColumn<int>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationDaysMeta = const VerificationMeta(
    'durationDays',
  );
  @override
  late final GeneratedColumn<int> durationDays = GeneratedColumn<int>(
    'duration_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _withDriverMeta = const VerificationMeta(
    'withDriver',
  );
  @override
  late final GeneratedColumn<bool> withDriver = GeneratedColumn<bool>(
    'with_driver',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("with_driver" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pickupLocationMeta = const VerificationMeta(
    'pickupLocation',
  );
  @override
  late final GeneratedColumn<String> pickupLocation = GeneratedColumn<String>(
    'pickup_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pickupLatitudeMeta = const VerificationMeta(
    'pickupLatitude',
  );
  @override
  late final GeneratedColumn<double> pickupLatitude = GeneratedColumn<double>(
    'pickup_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pickupLongitudeMeta = const VerificationMeta(
    'pickupLongitude',
  );
  @override
  late final GeneratedColumn<double> pickupLongitude = GeneratedColumn<double>(
    'pickup_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerNoteMeta = const VerificationMeta(
    'customerNote',
  );
  @override
  late final GeneratedColumn<String> customerNote = GeneratedColumn<String>(
    'customer_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyRateMeta = const VerificationMeta(
    'dailyRate',
  );
  @override
  late final GeneratedColumn<int> dailyRate = GeneratedColumn<int>(
    'daily_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceFeeMeta = const VerificationMeta(
    'serviceFee',
  );
  @override
  late final GeneratedColumn<int> serviceFee = GeneratedColumn<int>(
    'service_fee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentBankMeta = const VerificationMeta(
    'paymentBank',
  );
  @override
  late final GeneratedColumn<String> paymentBank = GeneratedColumn<String>(
    'payment_bank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentAccountNumberMeta =
      const VerificationMeta('paymentAccountNumber');
  @override
  late final GeneratedColumn<String> paymentAccountNumber =
      GeneratedColumn<String>(
        'payment_account_number',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isFinalTariffConfirmedMeta =
      const VerificationMeta('isFinalTariffConfirmed');
  @override
  late final GeneratedColumn<bool> isFinalTariffConfirmed =
      GeneratedColumn<bool>(
        'is_final_tariff_confirmed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_final_tariff_confirmed" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFetchedMeta = const VerificationMeta(
    'lastFetched',
  );
  @override
  late final GeneratedColumn<int> lastFetched = GeneratedColumn<int>(
    'last_fetched',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    startDate,
    startTime,
    durationDays,
    withDriver,
    pickupLocation,
    pickupLatitude,
    pickupLongitude,
    customerNote,
    status,
    dailyRate,
    serviceFee,
    paymentBank,
    paymentAccountNumber,
    isFinalTariffConfirmed,
    createdAt,
    lastFetched,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Booking> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_days')) {
      context.handle(
        _durationDaysMeta,
        durationDays.isAcceptableOrUnknown(
          data['duration_days']!,
          _durationDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationDaysMeta);
    }
    if (data.containsKey('with_driver')) {
      context.handle(
        _withDriverMeta,
        withDriver.isAcceptableOrUnknown(data['with_driver']!, _withDriverMeta),
      );
    }
    if (data.containsKey('pickup_location')) {
      context.handle(
        _pickupLocationMeta,
        pickupLocation.isAcceptableOrUnknown(
          data['pickup_location']!,
          _pickupLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pickupLocationMeta);
    }
    if (data.containsKey('pickup_latitude')) {
      context.handle(
        _pickupLatitudeMeta,
        pickupLatitude.isAcceptableOrUnknown(
          data['pickup_latitude']!,
          _pickupLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('pickup_longitude')) {
      context.handle(
        _pickupLongitudeMeta,
        pickupLongitude.isAcceptableOrUnknown(
          data['pickup_longitude']!,
          _pickupLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('customer_note')) {
      context.handle(
        _customerNoteMeta,
        customerNote.isAcceptableOrUnknown(
          data['customer_note']!,
          _customerNoteMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('daily_rate')) {
      context.handle(
        _dailyRateMeta,
        dailyRate.isAcceptableOrUnknown(data['daily_rate']!, _dailyRateMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyRateMeta);
    }
    if (data.containsKey('service_fee')) {
      context.handle(
        _serviceFeeMeta,
        serviceFee.isAcceptableOrUnknown(data['service_fee']!, _serviceFeeMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceFeeMeta);
    }
    if (data.containsKey('payment_bank')) {
      context.handle(
        _paymentBankMeta,
        paymentBank.isAcceptableOrUnknown(
          data['payment_bank']!,
          _paymentBankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentBankMeta);
    }
    if (data.containsKey('payment_account_number')) {
      context.handle(
        _paymentAccountNumberMeta,
        paymentAccountNumber.isAcceptableOrUnknown(
          data['payment_account_number']!,
          _paymentAccountNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentAccountNumberMeta);
    }
    if (data.containsKey('is_final_tariff_confirmed')) {
      context.handle(
        _isFinalTariffConfirmedMeta,
        isFinalTariffConfirmed.isAcceptableOrUnknown(
          data['is_final_tariff_confirmed']!,
          _isFinalTariffConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_fetched')) {
      context.handle(
        _lastFetchedMeta,
        lastFetched.isAcceptableOrUnknown(
          data['last_fetched']!,
          _lastFetchedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFetchedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Booking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Booking(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      durationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_days'],
      )!,
      withDriver: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}with_driver'],
      )!,
      pickupLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pickup_location'],
      )!,
      pickupLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pickup_latitude'],
      ),
      pickupLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pickup_longitude'],
      ),
      customerNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dailyRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_rate'],
      )!,
      serviceFee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_fee'],
      )!,
      paymentBank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_bank'],
      )!,
      paymentAccountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_account_number'],
      )!,
      isFinalTariffConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_final_tariff_confirmed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastFetched: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fetched'],
      )!,
    );
  }

  @override
  $BookingsTable createAlias(String alias) {
    return $BookingsTable(attachedDatabase, alias);
  }
}

class Booking extends DataClass implements Insertable<Booking> {
  /// Kode pemesanan unik (contoh: 'MKQ-2026-001')
  final String id;

  /// ID referensi armada kendaraan
  final String vehicleId;

  /// Tanggal mulai sewa (UTC epoch milliseconds)
  final int startDate;

  /// Waktu jam penjemputan (contoh: '09.00 WIT')
  final String startTime;

  /// Durasi penyewaan dalam satuan hari
  final int durationDays;

  /// Menggunakan supir (true) atau lepas kunci (false)
  final bool withDriver;

  /// Titik lokasi penjemputan di wilayah Merauke
  final String pickupLocation;

  /// Koordinat lintang penjemputan
  final double? pickupLatitude;

  /// Koordinat bujur penjemputan
  final double? pickupLongitude;

  /// Catatan khusus dari pelanggan
  final String? customerNote;

  /// Status pemesanan (nama enum: permintaanDiterima, pemeriksaanArmada, selesai, dll.)
  final String status;

  /// Tarif harian unit mobil saat dipesan
  final int dailyRate;

  /// Biaya layanan pemesanan
  final int serviceFee;

  /// Nama bank tujuan pembayaran
  final String paymentBank;

  /// Nomor rekening tujuan pembayaran
  final String paymentAccountNumber;

  /// Apakah tarif final sudah dikonfirmasi admin
  final bool isFinalTariffConfirmed;

  /// Waktu pembuatan pesanan (UTC epoch milliseconds)
  final int createdAt;

  /// Atribut penanda cache wajib: Waktu terakhir data di-fetch/di-cache (UTC Milliseconds)
  final int lastFetched;
  const Booking({
    required this.id,
    required this.vehicleId,
    required this.startDate,
    required this.startTime,
    required this.durationDays,
    required this.withDriver,
    required this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.customerNote,
    required this.status,
    required this.dailyRate,
    required this.serviceFee,
    required this.paymentBank,
    required this.paymentAccountNumber,
    required this.isFinalTariffConfirmed,
    required this.createdAt,
    required this.lastFetched,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['start_date'] = Variable<int>(startDate);
    map['start_time'] = Variable<String>(startTime);
    map['duration_days'] = Variable<int>(durationDays);
    map['with_driver'] = Variable<bool>(withDriver);
    map['pickup_location'] = Variable<String>(pickupLocation);
    if (!nullToAbsent || pickupLatitude != null) {
      map['pickup_latitude'] = Variable<double>(pickupLatitude);
    }
    if (!nullToAbsent || pickupLongitude != null) {
      map['pickup_longitude'] = Variable<double>(pickupLongitude);
    }
    if (!nullToAbsent || customerNote != null) {
      map['customer_note'] = Variable<String>(customerNote);
    }
    map['status'] = Variable<String>(status);
    map['daily_rate'] = Variable<int>(dailyRate);
    map['service_fee'] = Variable<int>(serviceFee);
    map['payment_bank'] = Variable<String>(paymentBank);
    map['payment_account_number'] = Variable<String>(paymentAccountNumber);
    map['is_final_tariff_confirmed'] = Variable<bool>(isFinalTariffConfirmed);
    map['created_at'] = Variable<int>(createdAt);
    map['last_fetched'] = Variable<int>(lastFetched);
    return map;
  }

  BookingsCompanion toCompanion(bool nullToAbsent) {
    return BookingsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      startDate: Value(startDate),
      startTime: Value(startTime),
      durationDays: Value(durationDays),
      withDriver: Value(withDriver),
      pickupLocation: Value(pickupLocation),
      pickupLatitude: pickupLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupLatitude),
      pickupLongitude: pickupLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(pickupLongitude),
      customerNote: customerNote == null && nullToAbsent
          ? const Value.absent()
          : Value(customerNote),
      status: Value(status),
      dailyRate: Value(dailyRate),
      serviceFee: Value(serviceFee),
      paymentBank: Value(paymentBank),
      paymentAccountNumber: Value(paymentAccountNumber),
      isFinalTariffConfirmed: Value(isFinalTariffConfirmed),
      createdAt: Value(createdAt),
      lastFetched: Value(lastFetched),
    );
  }

  factory Booking.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Booking(
      id: serializer.fromJson<String>(json['id']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      startDate: serializer.fromJson<int>(json['startDate']),
      startTime: serializer.fromJson<String>(json['startTime']),
      durationDays: serializer.fromJson<int>(json['durationDays']),
      withDriver: serializer.fromJson<bool>(json['withDriver']),
      pickupLocation: serializer.fromJson<String>(json['pickupLocation']),
      pickupLatitude: serializer.fromJson<double?>(json['pickupLatitude']),
      pickupLongitude: serializer.fromJson<double?>(json['pickupLongitude']),
      customerNote: serializer.fromJson<String?>(json['customerNote']),
      status: serializer.fromJson<String>(json['status']),
      dailyRate: serializer.fromJson<int>(json['dailyRate']),
      serviceFee: serializer.fromJson<int>(json['serviceFee']),
      paymentBank: serializer.fromJson<String>(json['paymentBank']),
      paymentAccountNumber: serializer.fromJson<String>(
        json['paymentAccountNumber'],
      ),
      isFinalTariffConfirmed: serializer.fromJson<bool>(
        json['isFinalTariffConfirmed'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastFetched: serializer.fromJson<int>(json['lastFetched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'startDate': serializer.toJson<int>(startDate),
      'startTime': serializer.toJson<String>(startTime),
      'durationDays': serializer.toJson<int>(durationDays),
      'withDriver': serializer.toJson<bool>(withDriver),
      'pickupLocation': serializer.toJson<String>(pickupLocation),
      'pickupLatitude': serializer.toJson<double?>(pickupLatitude),
      'pickupLongitude': serializer.toJson<double?>(pickupLongitude),
      'customerNote': serializer.toJson<String?>(customerNote),
      'status': serializer.toJson<String>(status),
      'dailyRate': serializer.toJson<int>(dailyRate),
      'serviceFee': serializer.toJson<int>(serviceFee),
      'paymentBank': serializer.toJson<String>(paymentBank),
      'paymentAccountNumber': serializer.toJson<String>(paymentAccountNumber),
      'isFinalTariffConfirmed': serializer.toJson<bool>(isFinalTariffConfirmed),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastFetched': serializer.toJson<int>(lastFetched),
    };
  }

  Booking copyWith({
    String? id,
    String? vehicleId,
    int? startDate,
    String? startTime,
    int? durationDays,
    bool? withDriver,
    String? pickupLocation,
    Value<double?> pickupLatitude = const Value.absent(),
    Value<double?> pickupLongitude = const Value.absent(),
    Value<String?> customerNote = const Value.absent(),
    String? status,
    int? dailyRate,
    int? serviceFee,
    String? paymentBank,
    String? paymentAccountNumber,
    bool? isFinalTariffConfirmed,
    int? createdAt,
    int? lastFetched,
  }) => Booking(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    startDate: startDate ?? this.startDate,
    startTime: startTime ?? this.startTime,
    durationDays: durationDays ?? this.durationDays,
    withDriver: withDriver ?? this.withDriver,
    pickupLocation: pickupLocation ?? this.pickupLocation,
    pickupLatitude: pickupLatitude.present
        ? pickupLatitude.value
        : this.pickupLatitude,
    pickupLongitude: pickupLongitude.present
        ? pickupLongitude.value
        : this.pickupLongitude,
    customerNote: customerNote.present ? customerNote.value : this.customerNote,
    status: status ?? this.status,
    dailyRate: dailyRate ?? this.dailyRate,
    serviceFee: serviceFee ?? this.serviceFee,
    paymentBank: paymentBank ?? this.paymentBank,
    paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
    isFinalTariffConfirmed:
        isFinalTariffConfirmed ?? this.isFinalTariffConfirmed,
    createdAt: createdAt ?? this.createdAt,
    lastFetched: lastFetched ?? this.lastFetched,
  );
  Booking copyWithCompanion(BookingsCompanion data) {
    return Booking(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationDays: data.durationDays.present
          ? data.durationDays.value
          : this.durationDays,
      withDriver: data.withDriver.present
          ? data.withDriver.value
          : this.withDriver,
      pickupLocation: data.pickupLocation.present
          ? data.pickupLocation.value
          : this.pickupLocation,
      pickupLatitude: data.pickupLatitude.present
          ? data.pickupLatitude.value
          : this.pickupLatitude,
      pickupLongitude: data.pickupLongitude.present
          ? data.pickupLongitude.value
          : this.pickupLongitude,
      customerNote: data.customerNote.present
          ? data.customerNote.value
          : this.customerNote,
      status: data.status.present ? data.status.value : this.status,
      dailyRate: data.dailyRate.present ? data.dailyRate.value : this.dailyRate,
      serviceFee: data.serviceFee.present
          ? data.serviceFee.value
          : this.serviceFee,
      paymentBank: data.paymentBank.present
          ? data.paymentBank.value
          : this.paymentBank,
      paymentAccountNumber: data.paymentAccountNumber.present
          ? data.paymentAccountNumber.value
          : this.paymentAccountNumber,
      isFinalTariffConfirmed: data.isFinalTariffConfirmed.present
          ? data.isFinalTariffConfirmed.value
          : this.isFinalTariffConfirmed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastFetched: data.lastFetched.present
          ? data.lastFetched.value
          : this.lastFetched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Booking(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('startDate: $startDate, ')
          ..write('startTime: $startTime, ')
          ..write('durationDays: $durationDays, ')
          ..write('withDriver: $withDriver, ')
          ..write('pickupLocation: $pickupLocation, ')
          ..write('pickupLatitude: $pickupLatitude, ')
          ..write('pickupLongitude: $pickupLongitude, ')
          ..write('customerNote: $customerNote, ')
          ..write('status: $status, ')
          ..write('dailyRate: $dailyRate, ')
          ..write('serviceFee: $serviceFee, ')
          ..write('paymentBank: $paymentBank, ')
          ..write('paymentAccountNumber: $paymentAccountNumber, ')
          ..write('isFinalTariffConfirmed: $isFinalTariffConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastFetched: $lastFetched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    startDate,
    startTime,
    durationDays,
    withDriver,
    pickupLocation,
    pickupLatitude,
    pickupLongitude,
    customerNote,
    status,
    dailyRate,
    serviceFee,
    paymentBank,
    paymentAccountNumber,
    isFinalTariffConfirmed,
    createdAt,
    lastFetched,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Booking &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.startDate == this.startDate &&
          other.startTime == this.startTime &&
          other.durationDays == this.durationDays &&
          other.withDriver == this.withDriver &&
          other.pickupLocation == this.pickupLocation &&
          other.pickupLatitude == this.pickupLatitude &&
          other.pickupLongitude == this.pickupLongitude &&
          other.customerNote == this.customerNote &&
          other.status == this.status &&
          other.dailyRate == this.dailyRate &&
          other.serviceFee == this.serviceFee &&
          other.paymentBank == this.paymentBank &&
          other.paymentAccountNumber == this.paymentAccountNumber &&
          other.isFinalTariffConfirmed == this.isFinalTariffConfirmed &&
          other.createdAt == this.createdAt &&
          other.lastFetched == this.lastFetched);
}

class BookingsCompanion extends UpdateCompanion<Booking> {
  final Value<String> id;
  final Value<String> vehicleId;
  final Value<int> startDate;
  final Value<String> startTime;
  final Value<int> durationDays;
  final Value<bool> withDriver;
  final Value<String> pickupLocation;
  final Value<double?> pickupLatitude;
  final Value<double?> pickupLongitude;
  final Value<String?> customerNote;
  final Value<String> status;
  final Value<int> dailyRate;
  final Value<int> serviceFee;
  final Value<String> paymentBank;
  final Value<String> paymentAccountNumber;
  final Value<bool> isFinalTariffConfirmed;
  final Value<int> createdAt;
  final Value<int> lastFetched;
  final Value<int> rowid;
  const BookingsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationDays = const Value.absent(),
    this.withDriver = const Value.absent(),
    this.pickupLocation = const Value.absent(),
    this.pickupLatitude = const Value.absent(),
    this.pickupLongitude = const Value.absent(),
    this.customerNote = const Value.absent(),
    this.status = const Value.absent(),
    this.dailyRate = const Value.absent(),
    this.serviceFee = const Value.absent(),
    this.paymentBank = const Value.absent(),
    this.paymentAccountNumber = const Value.absent(),
    this.isFinalTariffConfirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastFetched = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookingsCompanion.insert({
    required String id,
    required String vehicleId,
    required int startDate,
    required String startTime,
    required int durationDays,
    this.withDriver = const Value.absent(),
    required String pickupLocation,
    this.pickupLatitude = const Value.absent(),
    this.pickupLongitude = const Value.absent(),
    this.customerNote = const Value.absent(),
    required String status,
    required int dailyRate,
    required int serviceFee,
    required String paymentBank,
    required String paymentAccountNumber,
    this.isFinalTariffConfirmed = const Value.absent(),
    required int createdAt,
    required int lastFetched,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       vehicleId = Value(vehicleId),
       startDate = Value(startDate),
       startTime = Value(startTime),
       durationDays = Value(durationDays),
       pickupLocation = Value(pickupLocation),
       status = Value(status),
       dailyRate = Value(dailyRate),
       serviceFee = Value(serviceFee),
       paymentBank = Value(paymentBank),
       paymentAccountNumber = Value(paymentAccountNumber),
       createdAt = Value(createdAt),
       lastFetched = Value(lastFetched);
  static Insertable<Booking> custom({
    Expression<String>? id,
    Expression<String>? vehicleId,
    Expression<int>? startDate,
    Expression<String>? startTime,
    Expression<int>? durationDays,
    Expression<bool>? withDriver,
    Expression<String>? pickupLocation,
    Expression<double>? pickupLatitude,
    Expression<double>? pickupLongitude,
    Expression<String>? customerNote,
    Expression<String>? status,
    Expression<int>? dailyRate,
    Expression<int>? serviceFee,
    Expression<String>? paymentBank,
    Expression<String>? paymentAccountNumber,
    Expression<bool>? isFinalTariffConfirmed,
    Expression<int>? createdAt,
    Expression<int>? lastFetched,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (startDate != null) 'start_date': startDate,
      if (startTime != null) 'start_time': startTime,
      if (durationDays != null) 'duration_days': durationDays,
      if (withDriver != null) 'with_driver': withDriver,
      if (pickupLocation != null) 'pickup_location': pickupLocation,
      if (pickupLatitude != null) 'pickup_latitude': pickupLatitude,
      if (pickupLongitude != null) 'pickup_longitude': pickupLongitude,
      if (customerNote != null) 'customer_note': customerNote,
      if (status != null) 'status': status,
      if (dailyRate != null) 'daily_rate': dailyRate,
      if (serviceFee != null) 'service_fee': serviceFee,
      if (paymentBank != null) 'payment_bank': paymentBank,
      if (paymentAccountNumber != null)
        'payment_account_number': paymentAccountNumber,
      if (isFinalTariffConfirmed != null)
        'is_final_tariff_confirmed': isFinalTariffConfirmed,
      if (createdAt != null) 'created_at': createdAt,
      if (lastFetched != null) 'last_fetched': lastFetched,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookingsCompanion copyWith({
    Value<String>? id,
    Value<String>? vehicleId,
    Value<int>? startDate,
    Value<String>? startTime,
    Value<int>? durationDays,
    Value<bool>? withDriver,
    Value<String>? pickupLocation,
    Value<double?>? pickupLatitude,
    Value<double?>? pickupLongitude,
    Value<String?>? customerNote,
    Value<String>? status,
    Value<int>? dailyRate,
    Value<int>? serviceFee,
    Value<String>? paymentBank,
    Value<String>? paymentAccountNumber,
    Value<bool>? isFinalTariffConfirmed,
    Value<int>? createdAt,
    Value<int>? lastFetched,
    Value<int>? rowid,
  }) {
    return BookingsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      durationDays: durationDays ?? this.durationDays,
      withDriver: withDriver ?? this.withDriver,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      customerNote: customerNote ?? this.customerNote,
      status: status ?? this.status,
      dailyRate: dailyRate ?? this.dailyRate,
      serviceFee: serviceFee ?? this.serviceFee,
      paymentBank: paymentBank ?? this.paymentBank,
      paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
      isFinalTariffConfirmed:
          isFinalTariffConfirmed ?? this.isFinalTariffConfirmed,
      createdAt: createdAt ?? this.createdAt,
      lastFetched: lastFetched ?? this.lastFetched,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<int>(startDate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (durationDays.present) {
      map['duration_days'] = Variable<int>(durationDays.value);
    }
    if (withDriver.present) {
      map['with_driver'] = Variable<bool>(withDriver.value);
    }
    if (pickupLocation.present) {
      map['pickup_location'] = Variable<String>(pickupLocation.value);
    }
    if (pickupLatitude.present) {
      map['pickup_latitude'] = Variable<double>(pickupLatitude.value);
    }
    if (pickupLongitude.present) {
      map['pickup_longitude'] = Variable<double>(pickupLongitude.value);
    }
    if (customerNote.present) {
      map['customer_note'] = Variable<String>(customerNote.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dailyRate.present) {
      map['daily_rate'] = Variable<int>(dailyRate.value);
    }
    if (serviceFee.present) {
      map['service_fee'] = Variable<int>(serviceFee.value);
    }
    if (paymentBank.present) {
      map['payment_bank'] = Variable<String>(paymentBank.value);
    }
    if (paymentAccountNumber.present) {
      map['payment_account_number'] = Variable<String>(
        paymentAccountNumber.value,
      );
    }
    if (isFinalTariffConfirmed.present) {
      map['is_final_tariff_confirmed'] = Variable<bool>(
        isFinalTariffConfirmed.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastFetched.present) {
      map['last_fetched'] = Variable<int>(lastFetched.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('startDate: $startDate, ')
          ..write('startTime: $startTime, ')
          ..write('durationDays: $durationDays, ')
          ..write('withDriver: $withDriver, ')
          ..write('pickupLocation: $pickupLocation, ')
          ..write('pickupLatitude: $pickupLatitude, ')
          ..write('pickupLongitude: $pickupLongitude, ')
          ..write('customerNote: $customerNote, ')
          ..write('status: $status, ')
          ..write('dailyRate: $dailyRate, ')
          ..write('serviceFee: $serviceFee, ')
          ..write('paymentBank: $paymentBank, ')
          ..write('paymentAccountNumber: $paymentAccountNumber, ')
          ..write('isFinalTariffConfirmed: $isFinalTariffConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastFetched: $lastFetched, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $BookingsTable bookings = $BookingsTable(this);
  late final VehicleDao vehicleDao = VehicleDao(this as AppDatabase);
  late final BookingDao bookingDao = BookingDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vehicles, bookings];
}

typedef $$VehiclesTableCreateCompanionBuilder = VehiclesCompanion Function({
  required String id,
  required String name,
  required String plateNumber,
  required String category,
  required String seatCapacity,
  required String transmission,
  required String bodyType,
  required String condition,
  required String availabilityTag,
  Value<bool> isPopular,
  required int pricePerDay,
  required String imageUrl,
  Value<String?> heroImageUrl,
  Value<String?> detailImageUrl,
  Value<bool> isFavorite,
  required int lastFetched,
  Value<int?> updatedAt,
  Value<int> rowid,
});
typedef $$VehiclesTableUpdateCompanionBuilder = VehiclesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> plateNumber,
  Value<String> category,
  Value<String> seatCapacity,
  Value<String> transmission,
  Value<String> bodyType,
  Value<String> condition,
  Value<String> availabilityTag,
  Value<bool> isPopular,
  Value<int> pricePerDay,
  Value<String> imageUrl,
  Value<String?> heroImageUrl,
  Value<String?> detailImageUrl,
  Value<bool> isFavorite,
  Value<int> lastFetched,
  Value<int?> updatedAt,
  Value<int> rowid,
});

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seatCapacity => $composableBuilder(
    column: $table.seatCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transmission => $composableBuilder(
    column: $table.transmission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyType => $composableBuilder(
    column: $table.bodyType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availabilityTag => $composableBuilder(
    column: $table.availabilityTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPopular => $composableBuilder(
    column: $table.isPopular,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerDay => $composableBuilder(
    column: $table.pricePerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailImageUrl => $composableBuilder(
    column: $table.detailImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seatCapacity => $composableBuilder(
    column: $table.seatCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transmission => $composableBuilder(
    column: $table.transmission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyType => $composableBuilder(
    column: $table.bodyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availabilityTag => $composableBuilder(
    column: $table.availabilityTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPopular => $composableBuilder(
    column: $table.isPopular,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerDay => $composableBuilder(
    column: $table.pricePerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailImageUrl => $composableBuilder(
    column: $table.detailImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get plateNumber => $composableBuilder(
    column: $table.plateNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get seatCapacity => $composableBuilder(
    column: $table.seatCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transmission => $composableBuilder(
    column: $table.transmission,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bodyType =>
      $composableBuilder(column: $table.bodyType, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get availabilityTag => $composableBuilder(
    column: $table.availabilityTag,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPopular =>
      $composableBuilder(column: $table.isPopular, builder: (column) => column);

  GeneratedColumn<int> get pricePerDay => $composableBuilder(
    column: $table.pricePerDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailImageUrl => $composableBuilder(
    column: $table.detailImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          Vehicle,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
          Vehicle,
          PrefetchHooks Function()
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> plateNumber = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> seatCapacity = const Value.absent(),
                Value<String> transmission = const Value.absent(),
                Value<String> bodyType = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String> availabilityTag = const Value.absent(),
                Value<bool> isPopular = const Value.absent(),
                Value<int> pricePerDay = const Value.absent(),
                Value<String> imageUrl = const Value.absent(),
                Value<String?> heroImageUrl = const Value.absent(),
                Value<String?> detailImageUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> lastFetched = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                name: name,
                plateNumber: plateNumber,
                category: category,
                seatCapacity: seatCapacity,
                transmission: transmission,
                bodyType: bodyType,
                condition: condition,
                availabilityTag: availabilityTag,
                isPopular: isPopular,
                pricePerDay: pricePerDay,
                imageUrl: imageUrl,
                heroImageUrl: heroImageUrl,
                detailImageUrl: detailImageUrl,
                isFavorite: isFavorite,
                lastFetched: lastFetched,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String plateNumber,
                required String category,
                required String seatCapacity,
                required String transmission,
                required String bodyType,
                required String condition,
                required String availabilityTag,
                Value<bool> isPopular = const Value.absent(),
                required int pricePerDay,
                required String imageUrl,
                Value<String?> heroImageUrl = const Value.absent(),
                Value<String?> detailImageUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required int lastFetched,
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                name: name,
                plateNumber: plateNumber,
                category: category,
                seatCapacity: seatCapacity,
                transmission: transmission,
                bodyType: bodyType,
                condition: condition,
                availabilityTag: availabilityTag,
                isPopular: isPopular,
                pricePerDay: pricePerDay,
                imageUrl: imageUrl,
                heroImageUrl: heroImageUrl,
                detailImageUrl: detailImageUrl,
                isFavorite: isFavorite,
                lastFetched: lastFetched,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, Vehicle>(table),
                  BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      Vehicle,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (Vehicle, BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle>),
      Vehicle,
      PrefetchHooks Function()
    >;
typedef $$BookingsTableCreateCompanionBuilder = BookingsCompanion Function({
  required String id,
  required String vehicleId,
  required int startDate,
  required String startTime,
  required int durationDays,
  Value<bool> withDriver,
  required String pickupLocation,
  Value<double?> pickupLatitude,
  Value<double?> pickupLongitude,
  Value<String?> customerNote,
  required String status,
  required int dailyRate,
  required int serviceFee,
  required String paymentBank,
  required String paymentAccountNumber,
  Value<bool> isFinalTariffConfirmed,
  required int createdAt,
  required int lastFetched,
  Value<int> rowid,
});
typedef $$BookingsTableUpdateCompanionBuilder = BookingsCompanion Function({
  Value<String> id,
  Value<String> vehicleId,
  Value<int> startDate,
  Value<String> startTime,
  Value<int> durationDays,
  Value<bool> withDriver,
  Value<String> pickupLocation,
  Value<double?> pickupLatitude,
  Value<double?> pickupLongitude,
  Value<String?> customerNote,
  Value<String> status,
  Value<int> dailyRate,
  Value<int> serviceFee,
  Value<String> paymentBank,
  Value<String> paymentAccountNumber,
  Value<bool> isFinalTariffConfirmed,
  Value<int> createdAt,
  Value<int> lastFetched,
  Value<int> rowid,
});

class $$BookingsTableFilterComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get withDriver => $composableBuilder(
    column: $table.withDriver,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pickupLocation => $composableBuilder(
    column: $table.pickupLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pickupLatitude => $composableBuilder(
    column: $table.pickupLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pickupLongitude => $composableBuilder(
    column: $table.pickupLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyRate => $composableBuilder(
    column: $table.dailyRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentBank => $composableBuilder(
    column: $table.paymentBank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentAccountNumber => $composableBuilder(
    column: $table.paymentAccountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFinalTariffConfirmed => $composableBuilder(
    column: $table.isFinalTariffConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleId => $composableBuilder(
    column: $table.vehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get withDriver => $composableBuilder(
    column: $table.withDriver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pickupLocation => $composableBuilder(
    column: $table.pickupLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pickupLatitude => $composableBuilder(
    column: $table.pickupLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pickupLongitude => $composableBuilder(
    column: $table.pickupLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyRate => $composableBuilder(
    column: $table.dailyRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentBank => $composableBuilder(
    column: $table.paymentBank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentAccountNumber => $composableBuilder(
    column: $table.paymentAccountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFinalTariffConfirmed => $composableBuilder(
    column: $table.isFinalTariffConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<int> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationDays => $composableBuilder(
    column: $table.durationDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get withDriver => $composableBuilder(
    column: $table.withDriver,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pickupLocation => $composableBuilder(
    column: $table.pickupLocation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pickupLatitude => $composableBuilder(
    column: $table.pickupLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pickupLongitude => $composableBuilder(
    column: $table.pickupLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerNote => $composableBuilder(
    column: $table.customerNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get dailyRate =>
      $composableBuilder(column: $table.dailyRate, builder: (column) => column);

  GeneratedColumn<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentBank => $composableBuilder(
    column: $table.paymentBank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentAccountNumber => $composableBuilder(
    column: $table.paymentAccountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFinalTariffConfirmed => $composableBuilder(
    column: $table.isFinalTariffConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastFetched => $composableBuilder(
    column: $table.lastFetched,
    builder: (column) => column,
  );
}

class $$BookingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookingsTable,
          Booking,
          $$BookingsTableFilterComposer,
          $$BookingsTableOrderingComposer,
          $$BookingsTableAnnotationComposer,
          $$BookingsTableCreateCompanionBuilder,
          $$BookingsTableUpdateCompanionBuilder,
          (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
          Booking,
          PrefetchHooks Function()
        > {
  $$BookingsTableTableManager(_$AppDatabase db, $BookingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<int> startDate = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<int> durationDays = const Value.absent(),
                Value<bool> withDriver = const Value.absent(),
                Value<String> pickupLocation = const Value.absent(),
                Value<double?> pickupLatitude = const Value.absent(),
                Value<double?> pickupLongitude = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> dailyRate = const Value.absent(),
                Value<int> serviceFee = const Value.absent(),
                Value<String> paymentBank = const Value.absent(),
                Value<String> paymentAccountNumber = const Value.absent(),
                Value<bool> isFinalTariffConfirmed = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastFetched = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookingsCompanion(
                id: id,
                vehicleId: vehicleId,
                startDate: startDate,
                startTime: startTime,
                durationDays: durationDays,
                withDriver: withDriver,
                pickupLocation: pickupLocation,
                pickupLatitude: pickupLatitude,
                pickupLongitude: pickupLongitude,
                customerNote: customerNote,
                status: status,
                dailyRate: dailyRate,
                serviceFee: serviceFee,
                paymentBank: paymentBank,
                paymentAccountNumber: paymentAccountNumber,
                isFinalTariffConfirmed: isFinalTariffConfirmed,
                createdAt: createdAt,
                lastFetched: lastFetched,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String vehicleId,
                required int startDate,
                required String startTime,
                required int durationDays,
                Value<bool> withDriver = const Value.absent(),
                required String pickupLocation,
                Value<double?> pickupLatitude = const Value.absent(),
                Value<double?> pickupLongitude = const Value.absent(),
                Value<String?> customerNote = const Value.absent(),
                required String status,
                required int dailyRate,
                required int serviceFee,
                required String paymentBank,
                required String paymentAccountNumber,
                Value<bool> isFinalTariffConfirmed = const Value.absent(),
                required int createdAt,
                required int lastFetched,
                Value<int> rowid = const Value.absent(),
              }) => BookingsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                startDate: startDate,
                startTime: startTime,
                durationDays: durationDays,
                withDriver: withDriver,
                pickupLocation: pickupLocation,
                pickupLatitude: pickupLatitude,
                pickupLongitude: pickupLongitude,
                customerNote: customerNote,
                status: status,
                dailyRate: dailyRate,
                serviceFee: serviceFee,
                paymentBank: paymentBank,
                paymentAccountNumber: paymentAccountNumber,
                isFinalTariffConfirmed: isFinalTariffConfirmed,
                createdAt: createdAt,
                lastFetched: lastFetched,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookingsTable, Booking>(table),
                  BaseReferences<_$AppDatabase, $BookingsTable, Booking>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookingsTable,
      Booking,
      $$BookingsTableFilterComposer,
      $$BookingsTableOrderingComposer,
      $$BookingsTableAnnotationComposer,
      $$BookingsTableCreateCompanionBuilder,
      $$BookingsTableUpdateCompanionBuilder,
      (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
      Booking,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$BookingsTableTableManager get bookings =>
      $$BookingsTableTableManager(_db, _db.bookings);
}
