import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../models/case_model.dart';
import '../providers/case_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // To navigate on logout

// --- Import http package if implementing actual fetching later ---
// import 'package:http/http.dart' as http;
// import 'dart:convert';


class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  // --- DIALOG 1: Add/Edit SINGLE Case ---
  void _showAddCaseDialog(BuildContext context, {CaseModel? existingCase}) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existingCase?.title ?? '');
    final descriptionController = TextEditingController(text: existingCase?.description ?? '');
    final priorityController = TextEditingController(text: existingCase?.priority.toString() ?? '');
    final bool isEditing = existingCase != null;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Case Details' : 'Add New Case'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Case Title', prefixIcon: Icon(Icons.title)),
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                  maxLines: 4, minLines: 2, textInputAction: TextInputAction.newline,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: priorityController,
                  decoration: const InputDecoration(labelText: 'Priority (0-100)', prefixIcon: Icon(Icons.priority_high)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [ FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3) ],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter priority';
                    final priority = int.tryParse(value);
                    if (priority == null || priority < 0 || priority > 100) return 'Enter a number between 0 and 100';
                    return null;
                  },
                   // Save when 'done' is pressed on keyboard
                   onFieldSubmitted: (_) => _saveCase(ctx, formKey, isEditing, existingCase, titleController, descriptionController, priorityController),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: <Widget>[
          TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop() ),
          ElevatedButton(
            child: Text(isEditing ? 'Update' : 'Add Case'),
            onPressed: () => _saveCase(ctx, formKey, isEditing, existingCase, titleController, descriptionController, priorityController),
          ),
        ],
      ),
    );
  }

  // Helper: Save logic for SINGLE case dialog
  void _saveCase(
      BuildContext dialogContext, GlobalKey<FormState> formKey, bool isEditing, CaseModel? existingCase,
      TextEditingController titleController, TextEditingController descriptionController, TextEditingController priorityController) {
    // Validate the form
    if (formKey.currentState?.validate() ?? false) {
      // Create or update the CaseModel
      final newOrUpdatedCase = CaseModel(
          id: existingCase?.id, // Use existing ID if editing
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: int.parse(priorityController.text),
          createdAt: existingCase?.createdAt // Keep original creation date if editing
      );
      // Access provider to add/update case
      final caseProvider = Provider.of<CaseProvider>(dialogContext, listen: false);
      if (isEditing) {
        caseProvider.updateCase(newOrUpdatedCase);
      } else {
        caseProvider.addCase(newOrUpdatedCase);
      }
      Navigator.of(dialogContext).pop(); // Close the dialog
    }
  }

  // --- DIALOG 2: Choice for adding single vs multiple ---
  void _showAddChoiceDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Case(s)'),
        contentPadding: const EdgeInsets.only(top: 10.0, bottom: 0), // Adjust padding
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.add_box_outlined, color: theme.colorScheme.primary),
              title: const Text('Add a Single Case'),
              subtitle: const Text('Enter details manually.'),
              onTap: () {
                Navigator.of(ctx).pop(); // Close choice dialog
                _showAddCaseDialog(context); // Open single case dialog
              },
            ),
            const Divider(height: 1), // Thin divider
            ListTile(
              leading: Icon(Icons.link_outlined, color: theme.colorScheme.primary),
              title: const Text('Import Multiple Cases'),
              subtitle: const Text('Fetch from a JSON link.'),
              onTap: () {
                 Navigator.of(ctx).pop(); // Close choice dialog
                 _showAddMultipleCasesDialog(context); // Open link input dialog
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // --- DIALOG 3: Input link for multiple cases ---
  void _showAddMultipleCasesDialog(BuildContext context) {
      final theme = Theme.of(context);
      final linkFormKey = GlobalKey<FormState>();
      final linkController = TextEditingController();
      bool isProcessingLink = false; // State managed by StatefulBuilder

      showDialog(
        context: context,
        barrierDismissible: false, // Don't dismiss while processing
        builder: (ctx) => StatefulBuilder( // Use StatefulBuilder for dialog's own state
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Import Cases from Link'),
              content: SingleChildScrollView(
                child: Form(
                  key: linkFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter the URL pointing to a JSON file containing a list of case objects.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: linkController,
                        decoration: const InputDecoration(
                          labelText: 'JSON URL',
                          prefixIcon: Icon(Icons.link),
                           hintText: 'https://example.com/cases.json'
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a URL';
                          // Basic URL validation
                           final uri = Uri.tryParse(value.trim());
                           if (uri == null || !uri.hasAbsolutePath || !uri.isAbsolute) {
                             return 'Please enter a valid URL';
                           }
                          return null;
                        },
                      ),
                      // Show loading indicator when processing
                      if (isProcessingLink)
                        const Padding(
                          padding: EdgeInsets.only(top: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  // Disable cancel while processing
                  onPressed: isProcessingLink ? null : () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('Import'),
                  // Disable import while processing
                  onPressed: isProcessingLink ? null : () async {
                      if (linkFormKey.currentState?.validate() ?? false) {
                        final url = linkController.text.trim();

                         // Show loading indicator inside the dialog
                         setDialogState(() { isProcessingLink = true; });

                         // --- TODO: Implement Actual Fetching Logic ---
                         // Requires 'http' package and error handling
                         // final bool success = await _fetchAndProcessCases(context, url);
                         //
                         // Placeholder Simulation:
                         print("HomeScreen: Attempting to import cases from URL: $url");
                         await Future.delayed(const Duration(seconds: 2)); // Simulate network/processing time
                         // Replace with actual result from _fetchAndProcessCases
                         bool success = true; // Assume success for placeholder
                         String message = "Simulated import successful!";
                         // if (!success) { message = "Import failed. Check URL/format or console."; }
                         // --- End of Placeholder ---

                         // Hide loading indicator
                         // Check if dialog is still mounted before setting state
                          if (dialogContext.mounted) {
                             setDialogState(() { isProcessingLink = false; });
                          }

                         // Check if dialog context is still valid before closing/showing snackbar
                         if (!dialogContext.mounted) return;

                         Navigator.of(dialogContext).pop(); // Close the import dialog

                         // Show feedback on the main screen
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text(message),
                             backgroundColor: success ? Colors.green[700] : theme.colorScheme.error,
                           ),
                         );
                      }
                  },
                ),
              ],
            );
          }
        ),
      );
  }

  // --- Placeholder Function for Fetching and Processing (Requires http package) ---
  // Future<bool> _fetchAndProcessCases(BuildContext context, String url) async {
  //   // Use Provider.of outside the loop if possible, or pass it in
  //   final caseProvider = Provider.of<CaseProvider>(context, listen: false);
  //   try {
  //     final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15)); // Add timeout

  //     if (response.statusCode == 200) {
  //       // Decode JSON safely
  //       final dynamic decodedData = jsonDecode(response.body);

  //       // Check if it's a List
  //       if (decodedData is List) {
  //         List<CaseModel> casesToAdd = [];
  //         int skippedCount = 0;
  //         for (var item in decodedData) {
  //           if (item is Map<String, dynamic>) {
  //             try {
  //               // Attempt to create CaseModel from map
  //               final newCase = CaseModel.fromJson(item);
  //               casesToAdd.add(newCase);
  //             } catch (e) {
  //               print("HomeScreen: Error parsing individual case item from JSON: $e, Item: $item");
  //               skippedCount++;
  //             }
  //           } else {
  //              skippedCount++;
  //              print("HomeScreen: Skipped item in JSON list because it was not a Map: $item");
  //           }
  //         }

  //         // Add valid cases in bulk
  //         if (casesToAdd.isNotEmpty) {
  //            await caseProvider.addMultipleCases(casesToAdd); // Use bulk add
  //         }

  //         print("HomeScreen: Successfully processed import. Added: ${casesToAdd.length}, Skipped: $skippedCount");
  //         return casesToAdd.isNotEmpty; // Return true if at least one was added
  //       } else {
  //         print("HomeScreen: Error - JSON data from URL is not a List.");
  //         return false;
  //       }
  //     } else {
  //       print("HomeScreen: Error fetching data from URL - Status code ${response.statusCode}");
  //       return false;
  //     }
  //   } catch (e) {
  //     print("HomeScreen: Error during fetching or processing cases from URL: $e");
  //     return false;
  //   }
  // }


  // --- Logout Function ---
  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    // Ensure context is still valid before navigating
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (Route<dynamic> route) => false, // Remove all routes below
      );
    }
  }

  // --- Confirmation Dialog for Deletion ---
  void _confirmDelete(BuildContext context, CaseModel caseToDelete) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false, // Must choose an action
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: RichText(
          text: TextSpan(
            style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Are you sure you want to permanently delete the case titled "'),
              TextSpan(text: caseToDelete.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: '"?'),
            ]
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error), // Use error color
            child: const Text('Delete'),
            onPressed: () {
              // Use context.read here as it's inside a callback
              context.read<CaseProvider>().removeCase(caseToDelete.id);
              Navigator.of(ctx).pop(); // Close the confirmation dialog
              // Show confirmation SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case deleted successfully'),
                    duration: Duration(seconds: 2),
                     // Style from SnackBarTheme
                  )
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Dialog to show full case details ---
  void _showCaseDetails(BuildContext context, CaseModel caseItem) {
     final theme = Theme.of(context);
     final priorityColor = _getPriorityColor(caseItem.priority);
     // Format date nicely
     final formattedDate = DateFormat('MMM d, yyyy HH:mm').format(caseItem.createdAt.toLocal());

     showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
           title: Text(caseItem.title, overflow: TextOverflow.ellipsis, maxLines: 2),
           content: SingleChildScrollView(
              child: ListBody( // Group related info
                children: <Widget>[
                  _buildDetailRow( context, 'Priority:', '${caseItem.priority}%', valueColor: priorityColor, valueWeight: FontWeight.bold ),
                  const Divider(height: 20, thickness: 0.5),
                  _buildDetailRow(context, 'Description:', caseItem.description),
                   const Divider(height: 20, thickness: 0.5),
                  _buildDetailRow(context, 'Created:', formattedDate),
                ],
              ),
           ),
           actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
           actions: <Widget>[
              TextButton(
                 child: const Text('Edit'),
                 onPressed: () {
                   Navigator.of(ctx).pop(); // Close details first
                   _showAddCaseDialog(context, existingCase: caseItem); // Then open edit
                 },
              ),
              ElevatedButton( // Make 'Close' more prominent
                 style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                 child: const Text('Close'),
                 onPressed: () => Navigator.of(ctx).pop(),
              ),
           ],
        ),
     );
  }

  // Helper widget for detail rows in the details dialog
  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, FontWeight? valueWeight}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
         text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4), // Default style with line height
            children: [
              TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)), // Label style
              TextSpan(text: value, style: TextStyle(color: valueColor ?? theme.textTheme.bodyMedium?.color, fontWeight: valueWeight)), // Value style
            ]
         ),
      ),
    );
  }

  // Helper widget for action buttons in the list item
  Widget _actionButton({ required BuildContext context, required IconData icon, required String tooltip, required Color color, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 20), // Icon size
      color: color, tooltip: tooltip, onPressed: onPressed,
      padding: const EdgeInsets.all(8), // Padding around icon
      constraints: const BoxConstraints(), // Remove extra constraints
      splashRadius: 20, // Size of ripple effect
      visualDensity: VisualDensity.compact, // Make icon button smaller
    );
  }

  // Helper function to determine color based on priority
  Color _getPriorityColor(int priority) {
    if (priority > 85) return const Color(0xFFc0392b); // Pomegranate Red
    if (priority > 65) return const Color(0xFFd35400); // Pumpkin Orange
    if (priority > 40) return const Color(0xFFf39c12); // Orange Yellow
    if (priority > 15) return const Color(0xFF27ae60); // Nephritis Green
    return const Color(0xFF2980b9); // Belize Hole Blue (for low priority)
  }


  @override
  Widget build(BuildContext context) {
    // Watch for changes in CaseProvider
    final caseProvider = context.watch<CaseProvider>();
    // Get the sorted list from the provider
    final sortedCases = caseProvider.sortedCases;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Cases'),
        automaticallyImplyLeading: false, // Don't show back button when coming from Login
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: sortedCases.isEmpty
          // --- Display Empty State ---
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon( Icons.inbox_outlined, size: 70, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4) ),
                     const SizedBox(height: 20),
                     Text( 'No Cases Found', style: theme.textTheme.headlineSmall?.copyWith(color: theme.textTheme.bodyMedium?.color), textAlign: TextAlign.center ),
                     const SizedBox(height: 10),
                     Text( 'Tap the + button below to add your first case and get started!', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center ),
                  ],
                ),
              ),
            )
          // --- Display Case List ---
          : RefreshIndicator( // Optional: Add pull-to-refresh
              onRefresh: () => caseProvider.loadCases(), // Call loadCases on refresh
              color: theme.colorScheme.secondary,
              backgroundColor: theme.colorScheme.primary,
              child: ListView.builder(
                // Add padding for visual spacing and FAB overlap avoidance
                padding: const EdgeInsets.only(top: 8, bottom: 90, left: 4, right: 4),
                itemCount: sortedCases.length,
                itemBuilder: (ctx, index) {
                  final currentCase = sortedCases[index];
                  final priorityColor = _getPriorityColor(currentCase.priority);

                  // Build each list item as a Card
                  return Card(
                    clipBehavior: Clip.antiAlias, // Clip ripple effect to card bounds
                    child: InkWell( // Make card tappable
                       onTap: () => _showCaseDetails(context, currentCase),
                       splashColor: priorityColor.withOpacity(0.1),
                       highlightColor: priorityColor.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 12, 12), // Custom padding LTRB
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically center
                          children: [
                            // Priority Indicator Bar (Left side)
                            Container(
                              width: 7, height: 65,
                               decoration: BoxDecoration( color: priorityColor, borderRadius: const BorderRadius.only( topRight: Radius.circular(4), bottomRight: Radius.circular(4)) ),
                               margin: const EdgeInsets.only(right: 16.0),
                            ),
                            // Case Title & Description (Takes available space)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text( currentCase.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis ),
                                  const SizedBox(height: 5),
                                  Text( currentCase.description, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis ),
                                  const SizedBox(height: 8),
                                  Text( 'Created: ${DateFormat('MMM d, yyyy').format(currentCase.createdAt.toLocal())}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)) ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10), // Spacer
                            // Priority % & Action Buttons (Right side)
                             Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               crossAxisAlignment: CrossAxisAlignment.end,
                               children: [
                                 Text( '${currentCase.priority}%', style: theme.textTheme.titleSmall?.copyWith( color: priorityColor, fontWeight: FontWeight.bold, fontSize: 15 ) ),
                                 const SizedBox(height: 10),
                                  Row( // Edit and Delete Buttons
                                     mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _actionButton( context: context, icon: Icons.edit_outlined, tooltip: 'Edit Case', color: theme.iconTheme.color ?? theme.primaryColor, onPressed: () => _showAddCaseDialog(context, existingCase: currentCase) ),
                                      const SizedBox(width: 8),
                                      _actionButton( context: context, icon: Icons.delete_outline, tooltip: 'Delete Case', color: theme.colorScheme.error.withOpacity(0.9), onPressed: () => _confirmDelete(context, currentCase) ),
                                    ],
                                  ),
                               ],
                             ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      // Floating Action Button to trigger add flow
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
        tooltip: 'Add New Case',
        onPressed: () => _showAddChoiceDialog(context), // Show choice dialog on press
      ),
    );
  }
}