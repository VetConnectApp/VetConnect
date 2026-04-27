import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'vetconnect_theme';
  static const _langKey = 'vetconnect_lang';

  bool _isDark = false;
  String _locale = 'en'; // 'en' | 'hi' | 'gu'

  bool get isDark => _isDark;
  String get locale => _locale;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getString(_themeKey) == 'dark';
    _locale = prefs.getString(_langKey) ?? 'en';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale);
    notifyListeners();
  }

  String get languageLabel {
    switch (_locale) {
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      default:
        return 'English';
    }
  }

  /// Translates a key given the current locale.
  String t(String key) {
    return _translations[_locale]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'dashboard': 'Dashboard',
      'scanner': 'Scanner',
      'profile': 'Profile',
      'sign_in': 'Sign In',
      'email': 'Email',
      'phone': 'Phone Number',
      'password': 'Password',
      'email_tab': 'Email',
      'phone_tab': 'Phone',
      'welcome_back': 'Welcome Back',
      'rural_mgmt': 'Rural Livestock Management',
      'vet_dashboard': 'Vet Dashboard',
      'farmer_dashboard': 'Farmer Dashboard',
      'admin_dashboard': 'Admin Dashboard',
      'total_treatments': 'Total Treatments',
      'pending': 'Pending',
      'approved': 'Approved',
      'my_herd': 'My Herd',
      'emergency_sos': '🚨 Emergency SOS',
      'scan_barcode': 'Scan Barcode',
      'scan_nfc': 'Tap NFC Tag',
      'camera_mode': 'Camera Mode',
      'nfc_mode': 'NFC Mode',
      'my_profile': 'My Profile',
      'license': 'License Number',
      'specialty': 'Specialization',
      'clinic': 'Clinic Name',
      'experience': 'Years of Experience',
      'farm_name': 'Farm Name',
      'cattle_count': 'Total Cattle Count',
      'village': 'Village / Location',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'save_profile': 'Save Profile',
      'logout': 'Logout',
      'register_cattle': 'Register New Cattle',
      'tag_id': 'Tag Number (Mandatory)',
      'species': 'Species',
      'breed': 'Breed',
      'farmer_email': 'Farmer Email (Owner)',
      'assign_nfc': '📡 Assign NFC Tag',
      'assign_barcode': '📷 Scan Barcode',
      'register': 'Register Animal',
      'cancel': 'Cancel',
      'treatment_log': 'Log Treatment',
      'routine': 'Routine',
      'urgent': 'Urgent',
      'surgery': 'Surgery',
      'treatment_notes': 'Treatment Notes...',
      'add_medicine': 'Add Medicine',
      'medicine': 'Medicine',
      'dosage': 'Dosage (e.g. 20ml)',
      'next_due': 'Next Due Date',
      'save_log': 'Save Log',
      'searching': 'Searching...',
      'not_found': 'Animal not found. Register new?',
      'sync_hub': 'Sync Hub',
      'all_synced': 'All Data Synced 🟢',
      'start_scanning': 'Point camera at a barcode\nor tap "NFC Mode" to scan a tag',
      'sos_description': 'Describe the emergency...',
      'sos_send': 'Send SOS',
      'sos_title': 'Emergency SOS',
      'no_treatments': 'No treatment records found.',
      'recent_treatments': 'Recent Treatments',
      'treatment_history': 'Treatment History',
      'department': 'Department',
      'admin_level': 'Admin Level',
    },
    'hi': {
      'dashboard': 'डैशबोर्ड',
      'scanner': 'स्कैनर',
      'profile': 'प्रोफ़ाइल',
      'sign_in': 'साइन इन करें',
      'email': 'ईमेल',
      'phone': 'फ़ोन नंबर',
      'password': 'पासवर्ड',
      'email_tab': 'ईमेल',
      'phone_tab': 'फ़ोन',
      'welcome_back': 'वापस स्वागत है',
      'rural_mgmt': 'ग्रामीण पशुधन प्रबंधन',
      'vet_dashboard': 'पशु चिकित्सक डैशबोर्ड',
      'farmer_dashboard': 'किसान डैशबोर्ड',
      'admin_dashboard': 'व्यवस्थापक डैशबोर्ड',
      'total_treatments': 'कुल उपचार',
      'pending': 'लंबित',
      'approved': 'स्वीकृत',
      'my_herd': 'मेरा झुंड',
      'emergency_sos': '🚨 आपातकालीन SOS',
      'scan_barcode': 'बारकोड स्कैन करें',
      'scan_nfc': 'NFC टैग टैप करें',
      'camera_mode': 'कैमरा मोड',
      'nfc_mode': 'NFC मोड',
      'my_profile': 'मेरी प्रोफ़ाइल',
      'license': 'लाइसेंस नंबर',
      'specialty': 'विशेषज्ञता',
      'clinic': 'क्लिनिक का नाम',
      'experience': 'अनुभव के वर्ष',
      'farm_name': 'खेत का नाम',
      'cattle_count': 'कुल पशु संख्या',
      'village': 'गाँव / स्थान',
      'dark_mode': 'डार्क मोड',
      'language': 'भाषा',
      'save_profile': 'प्रोफ़ाइल सहेजें',
      'logout': 'लॉग आउट',
      'register_cattle': 'नया पशु पंजीकृत करें',
      'tag_id': 'टैग नंबर (अनिवार्य)',
      'species': 'प्रजाति',
      'breed': 'नस्ल',
      'farmer_email': 'किसान का ईमेल (मालिक)',
      'assign_nfc': '📡 NFC टैग असाइन करें',
      'assign_barcode': '📷 बारकोड स्कैन करें',
      'register': 'पशु पंजीकृत करें',
      'cancel': 'रद्द करें',
      'treatment_log': 'उपचार लॉग करें',
      'routine': 'नियमित',
      'urgent': 'जरूरी',
      'surgery': 'सर्जरी',
      'treatment_notes': 'उपचार नोट्स...',
      'add_medicine': 'दवा जोड़ें',
      'medicine': 'दवा',
      'dosage': 'खुराक (उदा. 20ml)',
      'next_due': 'अगली देय तिथि',
      'save_log': 'लॉग सहेजें',
      'searching': 'खोज रहे हैं...',
      'not_found': 'पशु नहीं मिला। नया पंजीकृत करें?',
      'sync_hub': 'सिंक हब',
      'all_synced': 'सभी डेटा सिंक 🟢',
      'start_scanning': 'बारकोड पर कैमरा करें\nया NFC टैग टैप करें',
      'sos_description': 'आपातकाल का वर्णन करें...',
      'sos_send': 'SOS भेजें',
      'sos_title': 'आपातकालीन SOS',
      'no_treatments': 'कोई उपचार रिकॉर्ड नहीं मिला।',
      'recent_treatments': 'हाल के उपचार',
      'treatment_history': 'उपचार इतिहास',
      'department': 'विभाग',
      'admin_level': 'व्यवस्थापक स्तर',
    },
    'gu': {
      'dashboard': 'ડેશબોર્ડ',
      'scanner': 'સ્કેનર',
      'profile': 'પ્રોફાઇલ',
      'sign_in': 'સાઇન ઇન કરો',
      'email': 'ઇમેઇલ',
      'phone': 'ફોન નંબર',
      'password': 'પાસવર્ડ',
      'email_tab': 'ઇમેઇલ',
      'phone_tab': 'ફોન',
      'welcome_back': 'પાછા સ્વાગત છે',
      'rural_mgmt': 'ગ્રામીણ પશુધન વ્યવસ્થાપન',
      'vet_dashboard': 'પશુચિકિત્સક ડેશબોર્ડ',
      'farmer_dashboard': 'ખેડૂત ડેશબોર્ડ',
      'admin_dashboard': 'વ્યવસ્થાપક ડેશબોર્ડ',
      'total_treatments': 'કુલ સારવાર',
      'pending': 'બાકી',
      'approved': 'મંજૂર',
      'my_herd': 'મારો સમૂહ',
      'emergency_sos': '🚨 કટોકટી SOS',
      'scan_barcode': 'બારકોડ સ્કેન કરો',
      'scan_nfc': 'NFC ટૅગ ટૅપ કરો',
      'camera_mode': 'કૅમેરા મોડ',
      'nfc_mode': 'NFC મોડ',
      'my_profile': 'મારી પ્રોફાઇલ',
      'license': 'લાઇસન્સ નંબર',
      'specialty': 'વિશેષતા',
      'clinic': 'ક્લિનિકનું નામ',
      'experience': 'અનુભવ (વર્ષ)',
      'farm_name': 'ખેતરનું નામ',
      'cattle_count': 'કુલ પશુ સંખ્યા',
      'village': 'ગામ / સ્થળ',
      'dark_mode': 'ડાર્ક મોડ',
      'language': 'ભાષા',
      'save_profile': 'પ્રોફાઇલ સાચવો',
      'logout': 'લૉગ આઉટ',
      'register_cattle': 'નવું પશુ નોંધો',
      'tag_id': 'ટૅગ નંબર (ફરજિયાત)',
      'species': 'પ્રજાતિ',
      'breed': 'ઓલાદ',
      'farmer_email': 'ખેડૂતનું ઇમેઇલ (માલિક)',
      'assign_nfc': '📡 NFC ટૅગ અસાઇન કરો',
      'assign_barcode': '📷 બારકોડ સ્કૅન કરો',
      'register': 'પશુ નોંધો',
      'cancel': 'રદ કરો',
      'treatment_log': 'સારવાર લોગ કરો',
      'routine': 'નિયમિત',
      'urgent': 'તાત્કાલિક',
      'surgery': 'સર્જરી',
      'treatment_notes': 'સારવાર નોંધો...',
      'add_medicine': 'દવા ઉમેરો',
      'medicine': 'દવા',
      'dosage': 'ડોઝ (દા.ત. 20ml)',
      'next_due': 'આગામી નિયત તારીખ',
      'save_log': 'લોગ સાચવો',
      'searching': 'શોધી રહ્યા છીએ...',
      'not_found': 'પશુ મળ્યું નહીં. નવું નોંધો?',
      'sync_hub': 'સિંક હબ',
      'all_synced': 'તમામ ડેટા સિંક 🟢',
      'start_scanning': 'બારકોડ પર કૅમેરા રાખો\nઅથવા NFC ટૅગ ટૅપ કરો',
      'sos_description': 'કટોકટીનું વર્ણન કરો...',
      'sos_send': 'SOS મોકલો',
      'sos_title': 'કટોકટી SOS',
      'no_treatments': 'કોઈ સારવાર રેકોર્ડ મળ્યો નહીં.',
      'recent_treatments': 'તાજેતરની સારવાર',
      'treatment_history': 'સારવાર ઇતિહાસ',
      'department': 'વિભાગ',
      'admin_level': 'વ્યવસ્થાપક સ્તર',
    },
  };
}
