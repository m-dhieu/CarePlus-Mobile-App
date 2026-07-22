// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeUsersFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _docs = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeUsersCollection(_docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUsersCollection implements CollectionReference<Map<String, dynamic>> {
  FakeUsersCollection(this._docs);
  final Map<String, Map<String, dynamic>> _docs;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final id = path ?? 'auto-${_docs.length}';
    return FakeUserDoc(id, _docs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserDoc implements DocumentReference<Map<String, dynamic>> {
  FakeUserDoc(this.id, this._docs);

  @override
  final String id;
  final Map<String, Map<String, dynamic>> _docs;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _docs[id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final existing = _docs[id] ?? <String, dynamic>{};
    existing.addAll(Map<String, dynamic>.from(data));
    _docs[id] = existing;
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeUserSnapshot(id, _docs[id]);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    return Stream.fromFuture(get());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeUserSnapshot(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
