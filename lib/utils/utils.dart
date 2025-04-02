import 'package:intl/intl.dart';

class Utils {
  // Format DateTime to readable string
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  // Format DateTime with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy, h:mm a').format(date);
  }
  
  // Format relative dates like "Today", "Yesterday", etc.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    
    final aDate = DateTime(date.year, date.month, date.day);
    
    if (aDate == today) {
      return 'Today';
    } else if (aDate == yesterday) {
      return 'Yesterday';
    } else if (aDate == tomorrow) {
      return 'Tomorrow';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return formatDate(date);
    }
  }
  
  // Convert a string to title case
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // Generate initials from a name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    final names = name.split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    
    return names[0][0].toUpperCase() + names.last[0].toUpperCase();
  }
  
  // Check if a string is a valid email
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }
} 