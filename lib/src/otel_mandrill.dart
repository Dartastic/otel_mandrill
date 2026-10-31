// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_mandrill_suppression.dart';

const _tracerName = 'dartastic_otel_libs_mandrill';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class MandrillResult {
  /// Creates a result.
  const MandrillResult({
    this.messageId,
    this.sentCount,
    this.queuedCount,
    this.rejectedCount,
    this.invalidCount,
    this.rejectReason,
    this.templateName,
    this.subaccount,
    this.requestId,
    this.statusCode,
  });

  /// `_id` returned for the first message in batch.
  final String? messageId;

  /// `status == sent` count.
  final int? sentCount;

  /// `status == queued` count.
  final int? queuedCount;

  /// `status == rejected` count.
  final int? rejectedCount;

  /// `status == invalid` count (bad address syntax).
  final int? invalidCount;

  /// `reject_reason` (`hard-bounce` / `soft-bounce` / `spam` /
  /// `unsub` / `custom` / `invalid-sender` / `invalid` / `test-mode-
  /// limit` / `rule`).
  final String? rejectReason;

  /// Template slug used.
  final String? templateName;

  /// `subaccount` id.
  final String? subaccount;

  /// `X-Mandrill-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class MandrillCallResult<T> {
  /// Creates a call result.
  const MandrillCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final MandrillResult? result;
}

/// Wraps a Mandrill API call in a CLIENT span. [operation] is one of
/// `messages.send`, `messages.send_template`, `messages.search`,
/// `messages.info`, `messages.content`, `messages.parse`,
/// `templates.add`, `templates.render`, `templates.update`,
/// `templates.list`, `rejects.list`, `rejects.add`, `rejects.delete`,
/// `exports.activity`, `exports.rejects`, `webhooks.list`,
/// `webhooks.add`, `subaccounts.list`, `users.info`, `users.ping`.
Future<T> tracedMandrill<T>({
  required String operation,
  required Future<MandrillCallResult<T>> Function() invoke,
}) async {
  if (mandrillInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'mandrill',
    'rpc.method': operation,
    'mandrill.operation': operation,
  };

  final span = _tracer().startSpan(
    'mandrill $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.messageId != null) {
        extras.add(OTelAPI.attributeString(
          'mandrill.message.id',
          r.result!.messageId!,
        ));
      }
      if (r.result!.sentCount != null) {
        extras.add(OTelAPI.attributeInt(
          'mandrill.sent',
          r.result!.sentCount!,
        ));
      }
      if (r.result!.queuedCount != null) {
        extras.add(OTelAPI.attributeInt(
          'mandrill.queued',
          r.result!.queuedCount!,
        ));
      }
      if (r.result!.rejectedCount != null) {
        extras.add(OTelAPI.attributeInt(
          'mandrill.rejected',
          r.result!.rejectedCount!,
        ));
      }
      if (r.result!.invalidCount != null) {
        extras.add(OTelAPI.attributeInt(
          'mandrill.invalid',
          r.result!.invalidCount!,
        ));
      }
      if (r.result!.rejectReason != null) {
        extras.add(OTelAPI.attributeString(
          'mandrill.reject.reason',
          r.result!.rejectReason!,
        ));
      }
      if (r.result!.templateName != null) {
        extras.add(OTelAPI.attributeString(
          'mandrill.template.name',
          r.result!.templateName!,
        ));
      }
      if (r.result!.subaccount != null) {
        extras.add(OTelAPI.attributeString(
          'mandrill.subaccount',
          r.result!.subaccount!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'mandrill.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Mandrill HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
