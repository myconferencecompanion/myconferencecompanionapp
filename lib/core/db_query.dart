/// Awaits Supabase or demo query builders in [Future.wait].
Future<List<dynamic>> dbWait(List<dynamic> queries) =>
    Future.wait(queries.map((q) => q as Future<dynamic>));

/// Awaits a single Supabase or demo query builder.
Future<T> dbQuery<T>(dynamic query) => (query as Future<T>);
