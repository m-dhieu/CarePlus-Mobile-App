// Care+ unit tests — models, mappers, outbox, CareRepository
// run with `flutter test test/unit.dart`

import 'unit/helpers_and_models.dart' as helpers_and_models;
import 'unit/offline_first.dart' as offline_first;

void main() {
  helpers_and_models.main();
  offline_first.main();
}
