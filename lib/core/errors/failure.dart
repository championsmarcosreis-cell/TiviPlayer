import 'app_exception.dart';

class Failure {
  const Failure(this.message);

  final String message;

  factory Failure.fromError(Object error) {
    if (error is AppException) {
      return Failure(error.message);
    }

    return const Failure('Falha inesperada ao processar a requisição.');
  }
}
