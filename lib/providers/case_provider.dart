import 'dart:convert';
import 'package:flutter/foundation.dart'; // For ChangeNotifier and kDebugMode
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_model.dart';

class CaseProvider with ChangeNotifier {
  List<CaseModel> _cases = [];
  static const String _casesStorageKey = 'casesList'; // Key for SharedPreferences

  /// Getter for the sorted list of cases (descending priority).
  /// Returns a new sorted list each time to prevent modification of the internal list.
  List<CaseModel> get sortedCases {
    final sortedList = List<CaseModel>.from(_cases);
    // Sorts by priority (highest first), then by creation date (newest first) for ties
    sortedList.sort((a, b) {
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      } else {
        return b.createdAt.compareTo(a.createdAt); // Newest first if same priority
      }
    });
    return sortedList;
  }

  /// Loads cases from local SharedPreferences storage.
  Future<void> loadCases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? casesJson = prefs.getStringList(_casesStorageKey);

      if (casesJson != null) {
        _cases = casesJson.map((caseString) {
          try {
            return CaseModel.fromJsonString(caseString);
          } catch (e) {
             if (kDebugMode) {
               print("Error decoding case: $caseString \nError: $e");
             }
             return null; // Handle potential decoding errors gracefully
          }
        }).whereType<CaseModel>().toList(); // Filter out nulls if decoding failed

        if (kDebugMode) {
          print('Loaded ${_cases.length} cases from storage.');
        }
      } else {
        _cases = []; // Initialize with empty list if nothing is stored
        if (kDebugMode) {
          print('No cases found in storage. Initializing empty list.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cases from SharedPreferences: $e');
      }
      _cases = []; // Ensure _cases is at least an empty list on error
    } finally {
      notifyListeners(); // Notify listeners after loading (or on error)
    }
  }

  /// Adds a new case to the list and saves to storage.
  Future<void> addCase(CaseModel newCase) async {
    _cases.add(newCase);
    await _saveCases(); // Save updated list
    if (kDebugMode) {
      print('Added case: ${newCase.title}');
    }
    notifyListeners(); // Notify UI about the change
  }

  /// Removes a case by its ID and saves to storage.
  Future<void> removeCase(String caseId) async {
    final originalLength = _cases.length;
    _cases.removeWhere((c) => c.id == caseId);
    if (_cases.length < originalLength) { // Check if removal happened
        await _saveCases();
        if (kDebugMode) {
          print('Removed case with ID: $caseId');
        }
        notifyListeners();
    } else {
        if (kDebugMode) {
          print('Attempted to remove case with ID $caseId, but it was not found.');
        }
    }
  }

  /// Updates an existing case identified by its ID and saves to storage.
  Future<void> updateCase(CaseModel updatedCase) async {
     final index = _cases.indexWhere((c) => c.id == updatedCase.id);
     if (index != -1) {
       _cases[index] = updatedCase;
       await _saveCases();
       if (kDebugMode) {
         print('Updated case: ${updatedCase.title}');
       }
       notifyListeners();
     } else {
         if (kDebugMode) {
           print('Attempted to update case with ID ${updatedCase.id}, but it was not found.');
         }
     }
  }


  /// Helper method to save the current list of cases to SharedPreferences.
  Future<void> _saveCases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert each CaseModel to its JSON string representation
      final List<String> casesJson = _cases.map((c) => c.toJsonString()).toList();
      await prefs.setStringList(_casesStorageKey, casesJson);
      if (kDebugMode) {
        print('Saved ${_cases.length} cases to storage.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cases to SharedPreferences: $e');
      }
      // Optional: Consider showing an error message to the user if saving fails
    }
  }
}