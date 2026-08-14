import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  TranslationService._();

  static const String _prefKey = 'velan_is_tamil';

  // Global state to track if Tamil is selected
  static final ValueNotifier<bool> isTamil = ValueNotifier<bool>(false);

  /// Initializes the service by loading the saved language preference.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isTamil.value = prefs.getBool(_prefKey) ?? false;
  }

  /// Toggles language and saves to preferences
  static Future<void> toggleLanguage(bool isTamilSelected) async {
    isTamil.value = isTamilSelected;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isTamilSelected);
  }

  /// The dictionary mapping English strings to Tamil.
  static const Map<String, String> _dictionary = {
    // General
    'Velan': 'வேலன்',
    'Velan Billing': 'வேலன் பில்லிங்',
    'Settings': 'அமைப்புகள்',
    'Cancel': 'ரத்துசெய்',
    'Save': 'சேமி',
    'Close': 'மூடு',
    'Done': 'முடிந்தது',
    'Yes': 'ஆம்',
    'No': 'இல்லை',
    'Edit': 'திருத்து',
    'Delete': 'நீக்கு',
    'Search': 'தேடு',

    // Splash & Login
    'Enter PIN to Access': 'உள்நுழைய பின் குறியீட்டை உள்ளிடவும்',
    'PIN is incorrect': 'பின் குறியீடு தவறானது',

    // Home Screen
    'Categories': 'வகைகள்',
    'All Items': 'அனைத்து பொருட்கள்',
    'Search items...': 'பொருட்களை தேடு...',
    'Item added to cart': 'பொருள் கூடையில் சேர்க்கப்பட்டது',
    'Add items to cart': 'கூடையில் பொருட்களை சேர்க்கவும்',
    'Customer Name / Business': 'வாடிக்கையாளர் பெயர் / வணிகம்',
    'e.g. Walk-in Customer or Ramesh': 'எ.கா. வாடிக்கையாளர் அல்லது ரமேஷ்',
    'Mobile Number': 'மொபைல் எண்',
    '9876543210': '9876543210',
    'Payment Method': 'கட்டண முறை',
    'Clear All': 'அனைத்தையும் அழி',
    'Proceed to Bill': 'பில்லுக்குச் செல்லவும்',
    'Subtotal:': 'கூட்டுத்தொகை:',
    'GST Tax (5%):': 'ஜிஎஸ்டி வரி (5%):',
    'Total Payable:': 'செலுத்த வேண்டிய தொகை:',
    'Amount Paid:': 'செலுத்திய தொகை:',
    'Balance Amount:': 'மீதி தொகை:',
    'Generate Bill': 'பில் உருவாக்கு',
    'Customer mobile number must be exactly 10 digits.': 'வாடிக்கையாளர் மொபைல் எண் சரியாக 10 இலக்கங்களாக இருக்க வேண்டும்.',
    
    // Cart Screen
    'POS Billing Cart': 'பிஓஎஸ் பில்லிங் கூடை',
    'Presets: ': 'முன்னமைவுகள்: ',
    'Walk-in': 'நேரடி',
    'Regular Client': 'வழக்கமான வாடிக்கையாளர்',
    'Store Branch': 'கடை கிளை',
    'Items in Cart': 'கூடையில் உள்ள பொருட்கள்',
    'Cart is empty.': 'கூடை காலியாக உள்ளது.',
    'Remove': 'நீக்கு',
    'Subtotal': 'கூட்டுத்தொகை',
    'GST Tax (5%)': 'ஜிஎஸ்டி வரி (5%)',
    'Discount': 'தள்ளுபடி',
    'Grand Total': 'மொத்த தொகை',

    // Product Screen
    'Product Catalog': 'பொருள் பட்டியல்',
    'Stock limit reached for this product.': 'இந்த பொருளுக்கான இருப்பு வரம்பை எட்டியது.',

    // Settings Screen
    'PREFERENCES': 'விருப்பங்கள்',
    'APP INFO': 'பயன்பாடு விவரம்',
    'Store Cashier': 'கடை காசாளர்',
    'Printer Settings': 'பிரிண்டர் அமைப்புகள்',
    'Manage connected printer': 'இணைக்கப்பட்ட பிரிண்டரை நிர்வகி',
    'Dark Theme': 'இருண்ட தீம்',
    'Dark mode is ON': 'இருண்ட தீம் இயங்குகிறது',
    'Switch light / dark mode': 'ஒளி / இருண்ட தீமை மாற்றுக',
    'Notifications': 'அறிவிப்புகள்',
    'Order alerts and reminders': 'ஆர்டர் விழிப்பூட்டல்கள் மற்றும் நினைவூட்டல்கள்',
    'About Velan': 'வேலன் பற்றி',
    'Version 1.0.0': 'பதிப்பு 1.0.0',
    'Logout': 'வெளியேறு',
    'Language': 'மொழி',
    'Tamil Enabled': 'தமிழ் இயங்குகிறது',
    'Switch to Tamil or English': 'தமிழ் அல்லது ஆங்கிலத்திற்கு மாற்றுக',

    // Bill History Screen
    'Bills History Database': 'பில்கள் வரலாறு',
    'Mark as Paid': 'பணம் செலுத்தப்பட்டது என குறி',
    'Void / Refund Bill': 'ரத்து செய் / பணத்தைத் திருப்பு',
    'View': 'காண்பி',
    'Reprint': 'மறுபதிப்பு செய்',
    'Pending': 'நிலுவையில்',
    'Paid': 'செலுத்தப்பட்டது',
    'Refunded': 'திரும்பப் பெறப்பட்டது',

    // Bill Screen & Receipt
    'Tax Invoice & Receipt': 'வரி விலைப்பட்டியல் மற்றும் ரசீது',
    'Print': 'அச்சிடு',
    'Share': 'பகிர்',
    'No printer connected. Connect one in Printer settings.': 'பிரிண்டர் இணைக்கப்படவில்லை. பிரிண்டர் அமைப்புகளில் இணைக்கவும்.',

    // Printer Screen
    'Bluetooth Printer': 'ப்ளூடூத் பிரிண்டர்',
    'Test Print': 'சோதனை அச்சு',
    'Use Active': 'செயலில் உள்ளதைப் பயன்படுத்து',
    'Printer disconnected.': 'பிரிண்டர் துண்டிக்கப்பட்டது.',
    'Test receipt sent to the printer!': 'சோதனை ரசீது பிரிண்டருக்கு அனுப்பப்பட்டது!',
  };

  /// Retrieves the translated string for a given key.
  static String translate(String key) {
    if (!isTamil.value) return key; // Return English if Tamil is not enabled
    return _dictionary[key] ?? key;
  }
}

/// Extension to easily call `.tr` on any string
extension StringExtension on String {
  String get tr => TranslationService.translate(this);
}
