class ApiResponse<T> {
  String? error = null;
  String? errorCode = null;
  T? res = null;

  ApiResponse({this.error, this.errorCode, this.res});
}
