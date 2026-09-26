import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_assistant/core/constants/app_constants.dart';

class BusinessInfoService {
  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(AppConstants.prefBusinessName) ?? '',
      'address': prefs.getString(AppConstants.prefBusinessAddress) ?? '',
      'gstin': prefs.getString(AppConstants.prefGstin) ?? '',
      'phone': prefs.getString(AppConstants.prefBusinessPhone) ?? '',
      'email': prefs.getString(AppConstants.prefBusinessEmail) ?? '',
      'upiId': prefs.getString(AppConstants.prefUpiId),
      'bankDetails': prefs.getString(AppConstants.prefBankDetails),
    };
  }
}
