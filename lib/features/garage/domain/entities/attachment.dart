class Attachment {
  final int id;
  final String url;
  final String name;
  final String mimeType;
  final int size;

  const Attachment({
    required this.id,
    required this.url,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
}
