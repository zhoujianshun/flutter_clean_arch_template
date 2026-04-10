import 'package:flutter_clean_arch_template/core/network/base_api.dart';

/// Example of a shared API class extending BaseAPI.
///
/// Use this pattern for shared API endpoints (e.g., file upload, resources).
/// Feature-specific APIs should live in their own feature's data/datasources/.
///
/// ```dart
/// @singleton
/// class ResourceAPI extends BaseAPI {
///   ResourceAPI(super.apiClient);
///
///   Future<Either<Failure, UploadResult>> uploadFile(File file) async {
///     return handleApiCall(
///       apiClient.upload('/resource/upload', file: file),
///       UploadResult.fromJson,
///       logTag: 'ResourceAPI.uploadFile',
///     );
///   }
/// }
/// ```
class ExampleSharedAPI extends BaseAPI {
  ExampleSharedAPI(super.apiClient);
}
