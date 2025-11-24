const String storageBaseUrl =
    "https://firebasestorage.googleapis.com/v0/b/nutrilink-5f07f.firebasestorage.app/o/menus%2F";

String buildImageUrl(String fileName) {
  if (fileName.isEmpty) return '';
  
  // Jika fileName sudah berisi full URL, return langsung
  if (fileName.startsWith('http')) return fileName;
  
  // Encode filename untuk URL
  final encodedFileName = Uri.encodeComponent(fileName);
  return "$storageBaseUrl$encodedFileName?alt=media";
}
