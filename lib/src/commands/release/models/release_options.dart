/// A class representing the options for a release process.
///
/// This class stores the configuration options for a release, including:
/// - Whether the release is running in a Continuous Integration (CI) environment,
/// - The release prefix (e.g., for version tags),
/// - The branch name associated with the release,
/// - The version and build number for the release,
/// - The raw version of the tag prefix.
///
/// The class is immutable, meaning that its values are set during initialization
/// and cannot be changed afterward.
///
/// Example usage:
/// ```dart
/// final options = ReleaseOptions(
///   ci: true,
///   prefix: 'v',
///   branch: 'main',
///   version: '1.0.0',
///   buildNumber: '42',
/// );
/// ```
class ReleaseOptions {
  /// Creates a new instance of [ReleaseOptions] with the provided values.
  ///
  /// [ci] is a boolean indicating whether the release is running in a Continuous Integration (CI) environment.
  /// [prefix] is an optional string used as a prefix for release tags, with a default value of an empty string.
  /// [branch] is an optional string representing the branch name for the release.
  /// [version] is an optional string representing the version of the release.
  /// [buildNumber] is an optional string representing the build number for the release.
  /// [prefixRaw] is an optional string for the raw version of the tag prefix (e.g., without transformation).
  const ReleaseOptions({
    required this.ci,
    this.prefix = '',
    this.branch,
    this.version,
    this.buildNumber,
    this.prefixRaw,
  });

  /// The prefix to be used for the release, such as a version tag prefix (e.g., 'v1.0.0').
  final String prefix;

  /// The version string of the release, e.g., '1.0.0'.
  final String? version;

  /// The branch name associated with the release (e.g., 'main', 'develop').
  final String? branch;

  /// The build number of the release, e.g., '42'.
  final String? buildNumber;

  /// A boolean indicating whether the release is running in a Continuous Integration (CI) environment.
  final bool ci;

  /// The raw version of the tag prefix, which might not be transformed or formatted.
  final String? prefixRaw;
}
