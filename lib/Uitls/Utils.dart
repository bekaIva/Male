V nullSafeMapValue<K, V>(Map<K, V> map, K key) {
  if (map?.containsKey(key) ?? false) return map[key];
  return null;
}
