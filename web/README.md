# Drift web runtime assets

Flutter web cannot use the native SQLite library. These two files are the
**browser runtime** for our offline Drift database. Android and iOS do not
use this folder.

| File | Role |
|------|------|
| `sqlite3.wasm` | SQLite compiled to WebAssembly — the actual database engine in the browser |
| `drift_worker.js` | Background worker that opens/runs the DB off the UI thread and can share it across tabs |

They are loaded from `lib/database/app_database.dart` via:

```dart
DriftWebOptions(
  sqlite3Wasm: Uri.parse('drift/sqlite3.wasm'),
  driftWorker: Uri.parse('drift/drift_worker.js'),
)
```

## When to update

Bump these when you upgrade `drift` / `sqlite3` in `pubspec.lock`.

1. Check versions:
   ```bash
   grep -A2 '^ drift:' pubspec.lock
   grep -A2 '^ sqlite3:' pubspec.lock
   ```
2. Download matching releases:
   - `sqlite3.wasm` → [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases)
   - `drift_worker.js` → [drift releases]
3. These files must be in this folder

Current copies match roughly: **sqlite3 3.5.x** + **drift 2.34.x**.

**Note**:
> These are generated binaries/scripts from the Drift toolchain. Treat them like native SDK blobs, not app source.