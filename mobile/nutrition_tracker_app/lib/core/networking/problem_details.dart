class ProblemDetails {
  const ProblemDetails(
      {this.type,
      this.title,
      this.status,
      this.detail,
      this.instance,
      this.traceId,
      this.errors = const {}});
  final String? type, title, detail, instance, traceId;
  final int? status;
  final Map<String, List<String>> errors;
  factory ProblemDetails.fromJson(Map<String, dynamic> json) => ProblemDetails(
      type: json['type'] as String?,
      title: json['title'] as String?,
      status: json['status'] as int?,
      detail: json['detail'] as String?,
      instance: json['instance'] as String?,
      traceId: json['traceId'] as String?,
      errors: (json['errors'] as Map<String, dynamic>? ?? {}).map(
          (key, value) =>
              MapEntry(key, (value as List<dynamic>).cast<String>())));
}
