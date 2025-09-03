// lib/models/sync_status.dart

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
  conflict
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync Error';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }

  String get description {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Synchronizing data...';
      case SyncStatus.success:
        return 'Data synchronized successfully';
      case SyncStatus.error:
        return 'Failed to synchronize data';
      case SyncStatus.offline:
        return 'No internet connection';
      case SyncStatus.conflict:
        return 'Data conflict detected';
    }
  }

  bool get isActive => this == SyncStatus.syncing;
  bool get isError => this == SyncStatus.error || this == SyncStatus.conflict;
  bool get isSuccess => this == SyncStatus.success;
  bool get canRetry => this == SyncStatus.error || this == SyncStatus.offline;
}
