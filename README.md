# wawapoint

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Migration to SQLite

Historical versions of the app stored records in a plain JSON file (`wawapoint_records.json`) alongside an export/backup feature that produced the same JSON format. Recent releases now persist data in a local SQLite database using `sqflite`.

To upgrade existing users:

1. **Automatic migration** occurs when the database is opened for the first time and the legacy JSON file still exists. The file is read, all records are inserted into the new database, and the JSON file is deleted.
2. **Manual migration** is possible by using the "복원" (restore) button on the settings screen: pick any previously exported `.json` backup and the app will import its contents into SQLite automatically.

The `PointViewModel` and `RecordDatabase` classes provide the necessary APIs; developers can also call

```dart
final text = await File('path/to/backup.json').readAsString();
await viewModel.importBackup(text); // inserts into SQLite as well
```

Existing backups are fully compatible with the new storage layer.
