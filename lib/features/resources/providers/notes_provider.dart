import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote(Note note) {
    state = [...state, note];
  }

  void deleteNote(String noteId) {
    state = state.where((note) => note.id != noteId).toList();
  }

  List<Note> getNotesForResource(String resourceId) {
    return state.where((note) => note.resourceId == resourceId).toList();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

final resourceNotesProvider = Provider.family<List<Note>, String>((ref, resourceId) {
  final allNotes = ref.watch(notesProvider);
  return allNotes.where((note) => note.resourceId == resourceId).toList();
});

