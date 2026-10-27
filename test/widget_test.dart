import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/util.dart';

void main() {
  test('date keys round-trip', () {
    final DateTime d = DateTime(2026, 10, 21);
    expect(dateKey(d), '2026-10-21');
    expect(parseKey('2026-10-21'), d);
  });

  test('ordinals read naturally', () {
    expect(ord(1), '1st');
    expect(ord(2), '2nd');
    expect(ord(3), '3rd');
    expect(ord(11), '11th');
    expect(ord(22), '22nd');
    expect(ord(30), '30th');
  });

  test('numbers drop trailing zeros', () {
    expect(fmtNumber(2.0), '2');
    expect(fmtNumber(1.5), '1.5');
  });

  test('times format to 12-hour clock', () {
    expect(fmtTime('07:30'), '7:30 AM');
    expect(fmtTime('00:05'), '12:05 AM');
    expect(fmtTime('13:00'), '1:00 PM');
  });
}
