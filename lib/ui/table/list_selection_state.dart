class ListSelectionState<T> {
  ListSelectionState({required this.idSelector});

  final String Function(T item) idSelector;
  final Set<String> _selectedIds = <String>{};

  bool isSelected(T item) => _selectedIds.contains(idSelector(item));

  bool isIdSelected(String id) => _selectedIds.contains(id);

  void setSelected(T item, bool selected) {
    final String id = idSelector(item);
    if (selected) {
      _selectedIds.add(id);
    } else {
      _selectedIds.remove(id);
    }
  }

  void toggle(T item) {
    final String id = idSelector(item);
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  void selectSingle(T item) {
    _selectedIds
      ..clear()
      ..add(idSelector(item));
  }

  void clear() => _selectedIds.clear();

  bool get hasSelection => _selectedIds.isNotEmpty;

  int get length => _selectedIds.length;

  Set<String> get ids => _selectedIds;

  void removeMissing(Iterable<T> items) {
    final Set<String> current = items
        .map(idSelector)
        .toSet();
    _selectedIds.removeWhere((String id) => !current.contains(id));
  }
}
