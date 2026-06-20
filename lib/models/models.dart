import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────
enum UserRole { client, barber }

enum AppointmentStatus {
  confirmed,
  pending,
  cancelled,
  inProgress,
  finished,
}

extension AppointmentStatusExt on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.inProgress:
        return 'inProgress';
      case AppointmentStatus.finished:
        return 'finished';
    }
  }

  static AppointmentStatus fromString(String s) {
    switch (s) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'inProgress':
        return AppointmentStatus.inProgress;
      case 'finished':
        return AppointmentStatus.finished;
      default:
        return AppointmentStatus.pending;
    }
  }
}

extension AppointmentModelStatusExt on AppointmentModel {
  DateTime get endDateTime => dateTime.add(Duration(minutes: serviceDurationMinutes));

  AppointmentStatus get currentStatus {
    if (status == AppointmentStatus.confirmed) {
      final now = DateTime.now();
      if (!now.isBefore(dateTime) && now.isBefore(endDateTime)) {
        return AppointmentStatus.inProgress;
      }
      if (!now.isBefore(endDateTime)) {
        return AppointmentStatus.finished;
      }
    }
    return status;
  }
}
// ─── UserModel ────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool isPremium;
  final String? photoUrl;
  final String? barbershopId; // only for barbers

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isPremium = false,
    this.photoUrl,
    this.barbershopId,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'barber' ? UserRole.barber : UserRole.client,
      isPremium: map['isPremium'] ?? false,
      photoUrl: map['photoUrl'],
      barbershopId: map['barbershopId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'role': role == UserRole.barber ? 'barber' : 'client',
    'isPremium': isPremium,
    'photoUrl': photoUrl,
    'barbershopId': barbershopId,
  };
}

// ─── Barbershop ───────────────────────────────────────────────
class BarbershopModel {
  final String id;
  final String ownerId;
  final String name;
  final String subtitle;
  final String address;
  final String phone;
  final double rating;
  final int ratingCount;
  final String? coverUrl;
  final double lat;
  final double lng;
  final Map<String, String> hours; // e.g. {'Segunda': '09:00–19:00'}
  final bool isActive;

  BarbershopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.subtitle,
    required this.address,
    required this.phone,
    this.rating = 0,
    this.ratingCount = 0,
    this.coverUrl,
    required this.lat,
    required this.lng,
    required this.hours,
    this.isActive = true,
  });

  double get startingPrice => 0; // computed from services

  factory BarbershopModel.fromMap(String id, Map<String, dynamic> map) {
    return BarbershopModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      subtitle: map['subtitle'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      coverUrl: map['coverUrl'],
      lat: (map['lat'] ?? -23.5505).toDouble(),
      lng: (map['lng'] ?? -46.6333).toDouble(),
      hours: Map<String, String>.from(map['hours'] ?? {}),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'name': name,
    'subtitle': subtitle,
    'address': address,
    'phone': phone,
    'rating': rating,
    'ratingCount': ratingCount,
    'coverUrl': coverUrl,
    'lat': lat,
    'lng': lng,
    'hours': hours,
    'isActive': isActive,
  };
}

// ─── Service ──────────────────────────────────────────────────
class ServiceModel {
  final String id;
  final String barbershopId;
  final String name;
  final int durationMinutes;
  final double price;

  ServiceModel({
    required this.id,
    required this.barbershopId,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      barbershopId: map['barbershopId'] ?? '',
      name: map['name'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'barbershopId': barbershopId,
    'name': name,
    'durationMinutes': durationMinutes,
    'price': price,
  };
}

// ─── Appointment ──────────────────────────────────────────────
class AppointmentModel {
  final String id;
  final String clientId;
  final String clientName;
  final String barbershopId;
  final String barbershopName;
  final String barbershopAddress;
  final String barbershopPhone;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDurationMinutes;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String clientEmail;
  final String clientPhone;
  final String? barbershopCoverUrl;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.barbershopId,
    required this.barbershopName,
    required this.barbershopAddress,
    required this.barbershopPhone,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDurationMinutes,
    required this.dateTime,
    required this.status,
    this.barbershopCoverUrl,
    this.reviewLeft = false,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientEmail: map['clientEmail'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      barbershopId: map['barbershopId'] ?? '',
      barbershopName: map['barbershopName'] ?? '',
      barbershopAddress: map['barbershopAddress'] ?? '',
      barbershopPhone: map['barbershopPhone'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0).toDouble(),
      serviceDurationMinutes: map['serviceDurationMinutes'] ?? 0,
      dateTime: _parseDateTime(map['dateTime']),
      status: AppointmentStatusExt.fromString(map['status'] ?? 'pending'),
      barbershopCoverUrl: map['barbershopCoverUrl'],
      reviewLeft: map['reviewLeft'] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError.value(value, 'dateTime', 'Unsupported dateTime format');
  }

  final bool reviewLeft;

  AppointmentModel copyWith({bool? reviewLeft}) => AppointmentModel(
        id: id,
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        barbershopId: barbershopId,
        barbershopName: barbershopName,
        barbershopAddress: barbershopAddress,
        barbershopPhone: barbershopPhone,
        serviceId: serviceId,
        serviceName: serviceName,
        servicePrice: servicePrice,
        serviceDurationMinutes: serviceDurationMinutes,
        dateTime: dateTime,
        status: status,
        barbershopCoverUrl: barbershopCoverUrl,
        reviewLeft: reviewLeft ?? this.reviewLeft,
      );

  Map<String, dynamic> toMap() => {
    'clientId': clientId,
    'clientName': clientName,
    'clientEmail': clientEmail,
    'clientPhone': clientPhone,
    'barbershopId': barbershopId,
    'barbershopName': barbershopName,
    'barbershopAddress': barbershopAddress,
    'barbershopPhone': barbershopPhone,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'servicePrice': servicePrice,
    'serviceDurationMinutes': serviceDurationMinutes,
    'dateTime': Timestamp.fromDate(dateTime),
    'status': status.label,
    'barbershopCoverUrl': barbershopCoverUrl,
    'reviewLeft': reviewLeft,
  };
}

// ─── Review ───────────────────────────────────────────────────
class ReviewModel {
  final String id;
  final String appointmentId;
  final String clientId;
  final String clientName;
  final String barbershopId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.barbershopId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      barbershopId: map['barbershopId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'appointmentId': appointmentId,
    'clientId': clientId,
    'clientName': clientName,
    'barbershopId': barbershopId,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
