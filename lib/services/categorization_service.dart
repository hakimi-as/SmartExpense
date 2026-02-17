import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategorizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keyword mappings for auto-categorization
  static final Map<String, List<String>> _categoryKeywords = {
    'Food': [
      // Fast Food
      'mcdonald', 'mcdonalds', 'kfc', 'pizza', 'burger', 'subway', 'domino',
      'starbucks', 'coffee', 'cafe', 'restaurant', 'food', 'eat', 'makan',
      'nasi', 'mee', 'chicken', 'ayam', 'rice', 'mamak', 'kopitiam',
      'bakery', 'bread', 'roti', 'tea', 'teh', 'kopi', 'breakfast',
      'lunch', 'dinner', 'supper', 'snack', 'dessert', 'ice cream',
      'sushi', 'ramen', 'noodle', 'pasta', 'warung', 'gerai',
      // Malaysian chains
      'secret recipe', 'oldtown', 'papparich', 'marrybrown', 'texas chicken',
      'the chicken rice shop', 'sushi king', 'kenny rogers', 'family mart', 'cu mart'
    ],
    'Transport': [
      'grab', 'uber', 'taxi', 'bus', 'train', 'mrt', 'lrt', 'ktm', 'rapid',
      'petrol', 'gas', 'fuel', 'shell', 'petronas', 'petron', 'caltex',
      'parking', 'toll', 'plus', 'touch n go', 'tng', 'e-wallet',
      'car', 'motorcycle', 'bike', 'gojek', 'maxim', 'indriver',
      'airport', 'flight', 'airasia', 'mas', 'airline',
    ],
    'Shopping': [
      'lazada', 'shopee', 'amazon', 'zalora', 'uniqlo', 'h&m', 'zara',
      'mall', 'shopping', 'store', 'shop', 'buy', 'purchase', 'retail',
      'aeon', 'tesco', 'giant', 'mydin', 'econsave', 'lotus', 'jaya grocer',
      'ikea', 'mr diy', 'daiso', 'miniso', 'watson', 'guardian',
      'clothes', 'fashion', 'shoes', 'bag', 'accessories',
      'supermarket', 'grocery', 'market', 'pasar',
    ],
    'Bills': [
      'bill', 'utility', 'electric', 'water', 'internet', 'wifi', 'broadband',
      'phone', 'mobile', 'celcom', 'maxis', 'digi', 'u mobile', 'unifi',
      'astro', 'netflix', 'spotify', 'subscription', 'insurance',
      'rent', 'rental', 'sewa', 'tnb', 'tenaga', 'syabas', 'air selangor',
      'indah water', 'cukai', 'tax', 'assessment', 'maintenance',
    ],
    'Entertainment': [
      'movie', 'cinema', 'gsc', 'tgv', 'mbo', 'game', 'gaming', 'playstation',
      'xbox', 'nintendo', 'steam', 'concert', 'show', 'ticket', 'event',
      'karaoke', 'bowling', 'arcade', 'theme park', 'zoo', 'aquarium',
      'museum', 'gallery', 'sport', 'gym', 'fitness', 'spa', 'massage',
      'hobby', 'book', 'magazine', 'music', 'youtube', 'premium',
    ],
    'Health': [
      'hospital', 'clinic', 'doctor', 'medical', 'pharmacy', 'ubat',
      'medicine', 'health', 'dental', 'dentist', 'gigi', 'eye', 'optical',
      'vitamin', 'supplement', 'guardian', 'watson', 'caring',
      'checkup', 'consultation', 'treatment', 'therapy', 'physio',
    ],
    'Education': [
      'school', 'university', 'college', 'tuition', 'class', 'course',
      'book', 'textbook', 'stationery', 'education', 'learn', 'study',
      'exam', 'fee', 'yuran', 'sekolah', 'universiti', 'pengajian',
      'training', 'workshop', 'seminar', 'certificate', 'udemy', 'coursera',
    ],
  };

  /// Auto-categorize based on merchant/title
  String categorizeByKeyword(String text) {
    final lowerText = text.toLowerCase();

    for (var entry in _categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return 'Others'; // Default category
  }

  /// Get category suggestions with confidence scores
  List<CategorySuggestion> getSuggestions(String text) {
    final lowerText = text.toLowerCase();
    final suggestions = <CategorySuggestion>[];

    for (var entry in _categoryKeywords.entries) {
      int matchCount = 0;
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        final confidence = (matchCount / entry.value.length * 100).clamp(0, 100);
        suggestions.add(CategorySuggestion(
          category: entry.key,
          confidence: confidence.toDouble(),
          matchedKeywords: matchCount,
        ));
      }
    }

    // Sort by confidence (highest first)
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions;
  }

  /// Save user correction to learn from it
  Future<void> saveUserCorrection({
    required String userId,
    required String merchantName,
    required String suggestedCategory,
    required String selectedCategory,
  }) async {
    if (suggestedCategory != selectedCategory) {
      await _firestore.collection('category_corrections').add({
        'userId': userId,
        'merchantName': merchantName.toLowerCase(),
        'suggestedCategory': suggestedCategory,
        'selectedCategory': selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user's custom category for a merchant (learned from corrections)
  Future<String?> getUserPreferredCategory(String userId, String merchantName) async {
    final snapshot = await _firestore
        .collection('category_corrections')
        .where('userId', isEqualTo: userId)
        .where('merchantName', isEqualTo: merchantName.toLowerCase())
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['selectedCategory'] as String?;
    }
    return null;
  }

  /// Smart categorize - checks user preferences first, then keywords
  Future<String> smartCategorize(String userId, String text) async {
    // First, check if user has a preferred category for this merchant
    final userPreferred = await getUserPreferredCategory(userId, text);
    if (userPreferred != null) {
      return userPreferred;
    }

    // Otherwise, use keyword-based categorization
    return categorizeByKeyword(text);
  }
}

/// Category suggestion with confidence
class CategorySuggestion {
  final String category;
  final double confidence;
  final int matchedKeywords;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.matchedKeywords,
  });
}