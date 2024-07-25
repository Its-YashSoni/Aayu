
import 'package:get/get.dart';

class ScanController extends GetxController {
  var selectedScreen = 'Screens'.obs;
  var selectedScan = 'Explore Plants'.obs;

  final Map<String, List<String>> supplierCategories = {
    'Screens': ['Explore Plants', 'Identify Plants'],
  };


  void selectSupplier(String supplier) {
    selectedScreen.value = supplier;
    selectedScan.value =
    'Explore Plants'; // Reset category to 'All' when supplier changes

  }

  void selectCategory(String category) {
    selectedScan.value = category;

  }

  List<String> getCategoriesForSelectedSupplier() {
    return supplierCategories[selectedScreen.value] ?? ['Explore PLants'];
  }

}
