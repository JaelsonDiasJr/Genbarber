import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'package:genbarber/models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ════════════════════════════════════════════════════════════
  // BARBERSHOPS
  // ════════════════════════════════════════════════════════════

  Stream<List<BarbershopModel>> streamAllBarbershops() {
    return _db
        .collection('barbershops')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BarbershopModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<BarbershopModel?> getBarbershop(String id) async {
    final doc = await _db.collection('barbershops').doc(id).get();
    if (!doc.exists) return null;
    return BarbershopModel.fromMap(doc.id, doc.data()!);
  }

  Future<String?> getBarbershopIdByOwner(String ownerId) async {
    final snap = await _db
        .collection('barbershops')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Stream<BarbershopModel?> streamBarbershop(String id) {
    return _db.collection('barbershops').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BarbershopModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> updateBarbershop(BarbershopModel shop) async {
    await _db.collection('barbershops').doc(shop.id).update(shop.toMap());
  }

  Future<String?> uploadBarbershopCover(String shopId, File file) async {
    if (!file.existsSync()) {
      throw Exception('Arquivo de imagem não encontrado');
    }

    final extension = file.path.split('.').last;
    final ref = _storage.ref('barbershops/$shopId/cover.$extension');
    // Detecta o content-type (MIME type) a partir da extensão do arquivo
    final metadata = SettableMetadata(contentType: lookupMimeType(file.path));
    try {
      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();
      await _db.collection('barbershops').doc(shopId).update({'coverUrl': url});
      return url;
    } on FirebaseException catch (e) {
      // Exibe código e mensagem para diagnóstico
      final msg = 'FirebaseStorage error [code=${e.code}]: ${e.message}';
      // Em modo debug, imprimir no console para ajudar no logcat
      try {
        // ignore: avoid_print
        print('uploadBarbershopCover: $msg');
      } catch (_) {}
      throw Exception(msg);
    } catch (e) {
      try {
        // ignore: avoid_print
        print('uploadBarbershopCover generic error: $e');
      } catch (_) {}
      throw Exception('Erro ao enviar imagem: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  // SERVICES
  // ════════════════════════════════════════════════════════════

  Stream<List<ServiceModel>> streamServices(String barbershopId) {
    return _db
        .collection('services')
        .where('barbershopId', isEqualTo: barbershopId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ServiceModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<List<ServiceModel>> getServices(String barbershopId) async {
    final snap = await _db
        .collection('services')
        .where('barbershopId', isEqualTo: barbershopId)
        .get();
    return snap.docs.map((d) => ServiceModel.fromMap(d.id, d.data())).toList();
  }

  Future<ServiceModel> addService(ServiceModel service) async {
    final ref = await _db.collection('services').add(service.toMap());
    return ServiceModel.fromMap(ref.id, service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await _db.collection('services').doc(service.id).update(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
  }

  // ════════════════════════════════════════════════════════════
  // APPOINTMENTS
  // ════════════════════════════════════════════════════════════

  /// Client: stream of own appointments
  Stream<List<AppointmentModel>> streamClientAppointments(String clientId) {
    return _db
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Barber: stream of today's appointments for their shop
  Stream<List<AppointmentModel>> streamBarberAppointments(
      String barbershopId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day, 0, 0);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return _db
        .collection('appointments')
        .where('barbershopId', isEqualTo: barbershopId)
        .snapshots()
        .map((snap) {
          final appointments = snap.docs
              .map((d) => AppointmentModel.fromMap(d.id, d.data()))
              .where((a) => !a.dateTime.isBefore(start) && !a.dateTime.isAfter(end))
              .toList();
          appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return appointments;
        });
  }

  /// All appointments for the whole month (for agenda calendar indicators)
  Stream<List<AppointmentModel>> streamBarberAppointmentsForMonth(
      String barbershopId, DateTime month) {
    return _db
        .collection('appointments')
        .where('barbershopId', isEqualTo: barbershopId)
        .snapshots()
        .map((snap) {
          final start = DateTime(month.year, month.month, 1);
          final end = DateTime(month.year, month.month + 1, 1);
          return snap.docs
              .map((d) => AppointmentModel.fromMap(d.id, d.data()))
              .where((a) =>
                  !a.dateTime.isBefore(start) && a.dateTime.isBefore(end))
              .toList();
        });
  }

  /// Pending appointments for the whole month (for home screen)
  Stream<List<AppointmentModel>> streamMonthPendingAppointments(
      String barbershopId, DateTime month) {
    // Filtra só por barbershopId + status no Firestore (sem range de data,
    // evitando índice composto). O filtro do mês é feito no cliente.
    return _db
        .collection('appointments')
        .where('barbershopId', isEqualTo: barbershopId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final start = DateTime(month.year, month.month, 1);
          final end = DateTime(month.year, month.month + 1, 1);
          final list = snap.docs
              .map((d) => AppointmentModel.fromMap(d.id, d.data()))
              .where((a) =>
                  !a.dateTime.isBefore(start) && a.dateTime.isBefore(end))
              .toList();
          list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return list;
        });
  }

  /// All appointments for the barbershop (for billing)
  Stream<List<AppointmentModel>> streamAllBarberAppointments(
      String barbershopId) {
    return _db
        .collection('appointments')
        .where('barbershopId', isEqualTo: barbershopId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<AppointmentModel> createAppointment(AppointmentModel apt) async {
    final ref = await _db.collection('appointments').add(apt.toMap());
    return AppointmentModel.fromMap(ref.id, apt.toMap());
  }

  Future<void> updateAppointmentStatus(
      String aptId, AppointmentStatus status) async {
    await _db.collection('appointments').doc(aptId).update({
      'status': status.label,
    });
  }

  Future<void> cancelAppointment(String aptId) async {
    await updateAppointmentStatus(aptId, AppointmentStatus.cancelled);
  }

  Future<void> finishAppointment(String aptId) async {
    await _db.collection('appointments').doc(aptId).update({
      'status': AppointmentStatus.finished.label,
    });
  }

  // ════════════════════════════════════════════════════════════
  // REVIEWS
  // ════════════════════════════════════════════════════════════

  Future<void> submitReview(ReviewModel review) async {
    final batch = _db.batch();

    // 1. Save review
    final reviewRef = _db.collection('reviews').doc();
    batch.set(reviewRef, review.toMap());

    // 2. Mark appointment as reviewed
    final aptRef = _db.collection('appointments').doc(review.appointmentId);
    batch.update(aptRef, {'reviewLeft': true});

    // 3. Recalculate barbershop rating
    final shopRef = _db.collection('barbershops').doc(review.barbershopId);
    final shopSnap = await shopRef.get();
    if (shopSnap.exists) {
      final data = shopSnap.data()!;
      final currentRating = (data['rating'] ?? 0).toDouble();
      final currentCount = (data['ratingCount'] ?? 0) as int;
      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + review.rating) / newCount;
      batch.update(shopRef, {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'ratingCount': newCount,
      });
    }

    await batch.commit();
  }

  Stream<List<ReviewModel>> streamBarbershopReviews(String barbershopId) {
    return _db
        .collection('reviews')
        .where('barbershopId', isEqualTo: barbershopId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReviewModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ════════════════════════════════════════════════════════════
  // BLOCKED SLOTS (to avoid double booking)
  // ════════════════════════════════════════════════════════════

  Future<List<DateTime>> getBookedSlots(
      String barbershopId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day, 0, 0);
    final end = DateTime(day.year, day.month, day.day, 23, 59);
    final snap = await _db
        .collection('appointments')
        .where('barbershopId', isEqualTo: barbershopId)
        .where('status', whereIn: ['confirmed', 'pending'])
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => (d['dateTime'] as Timestamp).toDate()).toList();
  }
}
