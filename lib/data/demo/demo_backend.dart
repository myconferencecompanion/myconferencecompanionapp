import 'dart:async';

import 'package:nse_mobile/data/demo/demo_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-compatible query builder for demo mode.
class DemoQueryBuilder implements Future<dynamic> {
  DemoQueryBuilder(this._store, this._query);

  final DemoStore _store;
  DemoQuery _query;

  DemoQueryBuilder select([String columns = '*']) {
    _query = _query.copyWith(select: columns);
    return this;
  }

  DemoQueryBuilder eq(String column, Object value) {
    final filters = [..._query.filters, DemoFilter(column, value, DemoFilterOp.eq)];
    _query = _query.copyWith(filters: filters);
    return this;
  }

  DemoQueryBuilder gte(String column, Object value) {
    final filters = [..._query.filters, DemoFilter(column, value, DemoFilterOp.gte)];
    _query = _query.copyWith(filters: filters);
    return this;
  }

  DemoQueryBuilder inFilter(String column, List<dynamic> values) {
    final filters = [..._query.filters, DemoFilter(column, values, DemoFilterOp.inList)];
    _query = _query.copyWith(filters: filters);
    return this;
  }

  DemoQueryBuilder or(String filter) {
    _query = _query.copyWith(orFilter: filter);
    return this;
  }

  DemoQueryBuilder order(String column, {bool ascending = true}) {
    _query = _query.copyWith(orderCol: column, orderAsc: ascending);
    return this;
  }

  DemoQueryBuilder limit(int count) {
    _query = _query.copyWith(limit: count);
    return this;
  }

  DemoQueryBuilder maybeSingle() {
    _query = _query.copyWith(maybeSingle: true);
    return this;
  }

  DemoQueryBuilder single() {
    _query = _query.copyWith(single: true);
    return this;
  }

  DemoQueryBuilder insert(Object values) {
    if (values is List) {
      _query = _query.copyWith(mutation: DemoMutation.insertMany, payload: values);
    } else {
      _query = _query.copyWith(mutation: DemoMutation.insert, payload: values);
    }
    return this;
  }

  DemoQueryBuilder update(Map<String, dynamic> values) {
    _query = _query.copyWith(mutation: DemoMutation.update, payload: values);
    return this;
  }

  DemoQueryBuilder upsert(Object values) {
    _query = _query.copyWith(mutation: DemoMutation.upsert, payload: values);
    return this;
  }

  DemoQueryBuilder delete() {
    _query = _query.copyWith(mutation: DemoMutation.delete);
    return this;
  }

  DemoQueryBuilder match(Map<String, dynamic> values) {
    var builder = this;
    for (final entry in values.entries) {
      builder = builder.eq(entry.key, entry.value);
    }
    return builder;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return _store.execute(_query).then(onValue, onError: onError);
  }

  @override
  Future<dynamic> catchError(Function onError, {bool Function(Object error)? test}) {
    return _store.execute(_query).catchError(onError, test: test);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _store.execute(_query).whenComplete(action);
  }

  @override
  Stream<dynamic> asStream() => _store.execute(_query).asStream();

  @override
  Future<dynamic> timeout(Duration timeLimit, {FutureOr<dynamic> Function()? onTimeout}) {
    return _store.execute(_query).timeout(timeLimit, onTimeout: onTimeout);
  }
}

class DemoRealtimeChannel {
  DemoRealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    required String schema,
    required String table,
    PostgresChangeFilter? filter,
    void Function(PostgresChangePayload payload)? callback,
  }) =>
      this;

  void subscribe() {}
}

class DemoBackend {
  DemoBackend(this._store);
  final DemoStore _store;

  DemoQueryBuilder from(String table) {
    return DemoQueryBuilder(_store, DemoQuery(table: table));
  }

  DemoRealtimeChannel channel(String name) => DemoRealtimeChannel();

  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    if (fn == 'redeem_signup_code') {
      return _store.rpcRedeemCode(params?['_code'] as String? ?? '');
    }
    return null;
  }
}

class LiveBackend {
  LiveBackend(this._client);
  final SupabaseClient _client;

  dynamic from(String table) => _client.from(table);

  RealtimeChannel channel(String name) => _client.channel(name);

  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) =>
      _client.rpc(fn, params: params ?? {});
}
