class FirestoreImage {
  String downloadUrl;
  String refPath;
  Map<String, dynamic> toJson() =>
      {'downloadUrl': downloadUrl, 'refPath': refPath};
  FirestoreImage({this.downloadUrl, this.refPath});
  FirestoreImage.fromJson(Map<String, dynamic> json) {
    downloadUrl = json['downloadUrl'] as String;
    refPath = json['refPath'] as String;
  }
}
