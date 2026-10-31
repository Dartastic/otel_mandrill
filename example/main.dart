// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_mandrill/otel_mandrill.dart';

/// Traces Mandrill calls with OpenTelemetry.
///
/// `otel_mandrill` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Mandrill call in
/// [tracedMandrill]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'mandrill-example');

  // Wraps a Mandrill API call in a CLIENT span.
  final mandrillId = await tracedMandrill<String>(
    operation: 'messages.send',
    invoke: () async {
      // Make the Mandrill call here, then report what it returned.
      const id = 'mandrill_8f3a2c';
      return const MandrillCallResult(
          value: id,
          result: MandrillResult(
              messageId: '_id',
              sentCount: 3,
              queuedCount: 3,
              rejectedCount: 3,
              invalidCount: 3,
              rejectReason: 'reject_reason',
              templateName: 'example',
              subaccount: 'example',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedMandrill messages.send returned $mandrillId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMandrillInstrumentationAsync.
  await runWithoutMandrillInstrumentationAsync(
    () => tracedMandrill<String>(
      operation: 'messages.send',
      invoke: () async {
        const id = 'mandrill_8f3a2c';
        return const MandrillCallResult(
            value: id,
            result: MandrillResult(
                messageId: '_id',
                sentCount: 3,
                queuedCount: 3,
                rejectedCount: 3,
                invalidCount: 3,
                rejectReason: 'reject_reason',
                templateName: 'example',
                subaccount: 'example',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
