class FolderState {
  final String? selectedFolderPath;
  final bool isValidTakeoutFolder;
  final List<String> imageFiles;

  const FolderState({
    this.selectedFolderPath,
    this.isValidTakeoutFolder = false,
    this.imageFiles = const [],
  });

  FolderState copyWith({
    String? selectedFolderPath,
    bool? isValidTakeoutFolder,
    List<String>? imageFiles,
  }) {
    return FolderState(
      selectedFolderPath: selectedFolderPath ?? this.selectedFolderPath,
      isValidTakeoutFolder: isValidTakeoutFolder ?? this.isValidTakeoutFolder,
      imageFiles: imageFiles ?? this.imageFiles,
    );
  }
}

class OutputFolderConfig {
  final String? outputFolderPath;
  final bool isValidOutputFolder;
  final bool hasWritePermissions;

  const OutputFolderConfig({
    this.outputFolderPath,
    this.isValidOutputFolder = false,
    this.hasWritePermissions = false,
  });

  OutputFolderConfig copyWith({
    String? outputFolderPath,
    bool? isValidOutputFolder,
    bool? hasWritePermissions,
  }) {
    return OutputFolderConfig(
      outputFolderPath: outputFolderPath ?? this.outputFolderPath,
      isValidOutputFolder: isValidOutputFolder ?? this.isValidOutputFolder,
      hasWritePermissions: hasWritePermissions ?? this.hasWritePermissions,
    );
  }

  bool get isReadyForProcessing =>
      isValidOutputFolder && hasWritePermissions;
}