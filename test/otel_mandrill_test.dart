// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_mandrill/otel_mandrill.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_mandrill-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('messages.send_template records batch outcomes', () async {
    await tracedMandrill<String>(
      operation: 'messages.send_template',
      invoke: () async => const MandrillCallResult(
        value: 'ok',
        result: MandrillResult(
          messageId: 'msg-1',
          sentCount: 8,
          queuedCount: 1,
          rejectedCount: 1,
          invalidCount: 0,
          rejectReason: 'hard-bounce',
          templateName: 'welcome',
          subaccount: 'acme',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mandrill messages.send_template')!);
    expect(a['mandrill.sent'], 8);
    expect(a['mandrill.rejected'], 1);
    expect(a['mandrill.reject.reason'], 'hard-bounce');
    expect(a['mandrill.template.name'], 'welcome');
    expect(a['mandrill.subaccount'], 'acme');
  });

  test('suppression skips spans', () async {
    await runWithoutMandrillInstrumentationAsync(() async {
      await tracedMandrill<String>(
        operation: 'users.ping',
        invoke: () async => const MandrillCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('mandrill '), isEmpty);
  });
}
