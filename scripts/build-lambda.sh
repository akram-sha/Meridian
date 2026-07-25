#!/usr/bin/env bash
# Cross-compiles MeridianLambda for Amazon Linux and produces the bootstrap zip that both
# `samlocal` (LocalStack) and real SAM deploy. Swift Lambda binaries must match Amazon
# Linux's glibc, so the build runs inside Docker via the AWSLambdaPackager plugin — the
# same command works identically on a dev laptop and in CI.
#
# Output: .build/plugins/AWSLambdaPackager/outputs/AWSLambdaPackager/MeridianLambda/MeridianLambda.zip
set -euo pipefail

cd "$(dirname "$0")/.."

swift package archive --allow-network-connections docker --products MeridianLambda "$@"

ZIP=".build/plugins/AWSLambdaPackager/outputs/AWSLambdaPackager/MeridianLambda/MeridianLambda.zip"
if [[ ! -f "$ZIP" ]]; then
    echo "error: expected artifact not found at $ZIP" >&2
    exit 1
fi
echo "Lambda artifact ready: $ZIP ($(du -h "$ZIP" | cut -f1))"
