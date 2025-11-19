const String storageBaseUrl =
    "https://firebasestorage.googleapis.com/v0/b/gs://nutrilink-5f07f.firebasestorage.app/o/";

String buildImageUrl(String fileName) {
  return "$storageBaseUrl$fileName?alt=media";
}