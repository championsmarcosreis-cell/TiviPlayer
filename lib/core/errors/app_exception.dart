class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class XtreamRequestException extends AppException {
  const XtreamRequestException(super.message);
}

class XtreamUnauthorizedException extends AppException {
  const XtreamUnauthorizedException([
    super.message = 'Credenciais inválidas ou conta inativa.',
  ]);
}
