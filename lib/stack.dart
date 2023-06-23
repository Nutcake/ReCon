
class Stack<T> {
  final List<T> _data = <T>[];

  void push(T entry) => _data.add(entry);

  T pop() => _data.removeLast();

  T? get peek => _data.lastOrNull;

  List<T> get entries => List.from(_data);

  bool get isEmpty => _data.isEmpty;
}