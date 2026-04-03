class ShmemPtr {
  static const Map<String, Map<String, String>> table = {
    'Chusan': {
      'Rustnithm': 'RustnithmSharedMemory',
      'Laverita': r'Global\laverita_shmem_id',
      'Yubideck': r'Global\yubideck_shmem_id',
    },
    'Mu3': {
      'Default': r'Global\mu3_generic_id',
    },
    'Mai2': {
      'Default': r'Global\mai2_generic_id',
    },
  };

  static String get(String major, String minor) {
    return table[major]?[minor] ?? '';
  }
}