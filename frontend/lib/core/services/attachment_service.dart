import 'package:file_picker/file_picker.dart';

import '../models/conversation.dart';

abstract class AttachmentService {
  Future<List<Attachment>> pickImages();
  Future<List<Attachment>> pickFiles();
  Future<List<Attachment>> pickVideos();
  Future<List<Attachment>> pickAny();
}

class FilePickerAttachmentService implements AttachmentService {
  static int _counter = 0;
  String _newId() =>
      'att_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  AttachmentType _typeFor(String? ext, String? mime) {
    final e = (ext ?? '').toLowerCase();
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(e)) {
      return AttachmentType.image;
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(e)) {
      return AttachmentType.video;
    }
    return AttachmentType.file;
  }

  List<Attachment> _fromResult(FilePickerResult? result) {
    if (result == null) return [];
    return result.files.map((f) {
      final path = f.path ?? f.name;
      return Attachment(
        id: _newId(),
        name: f.name,
        path: path,
        type: _typeFor(f.extension, null),
        size: f.size,
      );
    }).toList();
  }

  @override
  Future<List<Attachment>> pickImages() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    return _fromResult(r);
  }

  @override
  Future<List<Attachment>> pickVideos() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    return _fromResult(r);
  }

  @override
  Future<List<Attachment>> pickFiles() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    return _fromResult(r);
  }

  @override
  Future<List<Attachment>> pickAny() => pickFiles();
}
// (no-op)
