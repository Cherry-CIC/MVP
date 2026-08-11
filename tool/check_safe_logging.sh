#!/usr/bin/env bash

set -euo pipefail

repository_root="$(git rev-parse --show-toplevel)"
cd "$repository_root"

failed=0

report_matches() {
  local title="$1"
  shift

  if "$@"; then
    printf '%s\n' "$title"
    failed=1
    return
  else
    local command_status=$?
    if ((command_status > 1)); then
      printf '%s\n' 'Safe logging guard could not complete its scan.'
      exit "$command_status"
    fi
  fi
}

report_matches \
  'Unsafe Dio logging dependency or interceptor found:' \
  rg -n \
    'pretty_dio_logger|PrettyDioLogger|(^|[^[:alnum:]_])LogInterceptor[[:space:]]*\(' \
    pubspec.yaml pubspec.lock lib

report_matches \
  'Full network logging options must not be enabled:' \
  rg -n \
    '(requestHeader|requestBody|responseHeader|responseBody)[[:space:]]*:[[:space:]]*true' \
    lib

report_matches \
  'Direct logging sink found outside the typed safe logger:' \
  rg -n \
    'package:logging/logging\.dart|dart:developer|(^|[^[:alnum:]_])(print|debugPrint)[[:space:]]*\(|Logger[[:space:]]*\(' \
    lib \
    -g '*.dart' \
    -g '!lib/core/services/safe_log.dart'

report_matches \
  'Direct web console logging sink found:' \
  rg -n \
    'console\.(log|warn|error)[[:space:]]*\(' \
    web public

report_matches \
  'Direct native logging sink found:' \
  rg -n \
    'System\.out|android\.util\.Log|(^|[^[:alnum:]_])Log\.[vdiew][[:space:]]*\(|NSLog[[:space:]]*\(|os_log|(^|[^[:alnum:]_])print[[:space:]]*\(' \
    android ios

report_matches \
  'Raw network object appears in an application logging call:' \
  rg -n -U \
    'SafeLog\.(event|count|http)\([^;]*(requestOptions|response\.data|queryParameters|\.headers|\.uri|\.path|DioException|toString\(\))' \
    lib \
    -g '*.dart'

if ((failed != 0)); then
  printf '%s\n' 'Safe logging guard failed.'
  exit 1
fi

printf '%s\n' 'Safe logging guard passed.'
