abstract class A { void foo(); }
class B implements A {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() { print("Success"); }
