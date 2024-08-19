extension Pipe<T> on T {
  R pipe<R>(R Function(T) f) => f(this);
}
