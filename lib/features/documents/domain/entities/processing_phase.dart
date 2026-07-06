/// The step the save/regeneration pipeline is currently on.
enum ProcessingPhase { idle, preparing, ocr, generatingPdf, saving, done }

extension ProcessingPhaseLabel on ProcessingPhase {
  String get label => switch (this) {
    ProcessingPhase.idle => '',
    ProcessingPhase.preparing => 'Preparing pages',
    ProcessingPhase.ocr => 'Recognizing text',
    ProcessingPhase.generatingPdf => 'Creating PDF',
    ProcessingPhase.saving => 'Saving',
    ProcessingPhase.done => 'Done',
  };
}
