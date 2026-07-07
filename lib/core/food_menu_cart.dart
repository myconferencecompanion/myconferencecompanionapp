/// Food cart rules — mirrors `src/routes/_authenticated/concierge.food.tsx` `bump()`.
class FoodMenuCart {
  FoodMenuCart._();

  /// Returns an updated cart, or `null` when the change is rejected (e.g. over item cap).
  static Map<String, int>? applyBump({
    required Map<String, int> cart,
    required String itemId,
    required int delta,
    required String? categoryId,
    required int itemMax,
    required Map<String, Map<String, dynamic>> itemMap,
  }) {
    final current = cart[itemId] ?? 0;
    final next = current + delta;
    final out = Map<String, int>.from(cart);

    if (next <= 0) {
      out.remove(itemId);
      return out;
    }
    if (next > itemMax) return null;

    // One item type per section: if adding a new item, drop any other item
    // already chosen in this section.
    if (current == 0) {
      for (final entry in cart.entries) {
        if (entry.key == itemId || entry.value <= 0) continue;
        final it = itemMap[entry.key];
        if (it != null && (it['category_id'] as String? ?? '') == (categoryId ?? '')) {
          out.remove(entry.key);
        }
      }
    }

    out[itemId] = next;
    return out;
  }

  static String itemLimitMessage(int itemMax) =>
      itemMax == 1 ? 'Only one of this item' : 'Max $itemMax of this item';
}
