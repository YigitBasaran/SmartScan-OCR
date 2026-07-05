import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';

/// A function returning "now". Overridable in tests for deterministic time.
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

/// The opened Hive documents box. Overridden in `main()` and in tests.
final documentsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('documentsBoxProvider must be overridden'),
);

/// The opened Hive settings box. Overridden in `main()` and in tests.
final settingsBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('settingsBoxProvider must be overridden'),
);
