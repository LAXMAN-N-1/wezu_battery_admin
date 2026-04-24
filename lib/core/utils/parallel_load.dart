/// Small helper for starting independent async work together and awaiting the
/// results with strong typing.
///
/// This is the default pattern for UI bootstrap loads where one slow read
/// should not delay unrelated API calls.
final class ParallelLoad {
  const ParallelLoad._();

  static Future<(A, B)> pair<A, B>(Future<A> first, Future<B> second) async {
    final firstFuture = first;
    final secondFuture = second;

    return (await firstFuture, await secondFuture);
  }

  static Future<(A, B, C)> trio<A, B, C>(
    Future<A> first,
    Future<B> second,
    Future<C> third,
  ) async {
    final firstFuture = first;
    final secondFuture = second;
    final thirdFuture = third;

    return (await firstFuture, await secondFuture, await thirdFuture);
  }
}
