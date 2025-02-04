import 'package:dio/dio.dart';

mixin RequestRetryMixin {
  Future<Response<R>> retry<R>({
    required Dio retryClient,
    required RequestOptions requestOptions,
    required Future<Map<String, dynamic>> Function() buildHeaders,
  }) async {
    return retryClient.request<R>(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data is FormData
          ? (requestOptions.data as FormData).clone()
          : requestOptions.data,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: requestOptions.extra,
        headers: requestOptions.headers..addAll(await buildHeaders()),
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat,
      ),
    );
  }
}
