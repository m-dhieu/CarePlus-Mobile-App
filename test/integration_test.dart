// Care+ integration tests — signed-in shell, Drift flows, auth/profile wiring
// run with `flutter test test/integration_test.dart`

import 'integration/app_shell.dart' as app_shell;
import 'integration/auth_profile.dart' as auth_profile;

void main() {
  app_shell.main();
  auth_profile.main();
}
