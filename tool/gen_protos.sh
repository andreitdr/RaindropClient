#!/usr/bin/env bash
# Regenerates the Dart for the Raindrop wire protocol from the sibling RaindropProto checkout into
# lib/core/network/grpc/generated/. The output is committed, so `flutter run` needs no generation step;
# run this after any change to RaindropProto and commit what it writes.
#
# Needs protoc (`brew install protobuf`) and the Dart plugin (`dart pub global activate protoc_plugin`,
# 25.x — it generates for the protobuf 6 runtime this app shares with livekit_client).
set -euo pipefail

CLIENT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO="${RAINDROP_PROTO_DIR:-$CLIENT/../RaindropProto}"
OUT="$CLIENT/lib/core/network/grpc/generated"
export PATH="$PATH:$HOME/.pub-cache/bin"

[ -f "$PROTO/raindrop/v1/server.proto" ] || {
    echo "RaindropProto was not found at $PROTO; clone it next to RaindropClient (or set RAINDROP_PROTO_DIR)." >&2
    exit 1
}
command -v protoc >/dev/null || { echo "protoc is missing: brew install protobuf" >&2; exit 1; }
command -v protoc-gen-dart >/dev/null || { echo "protoc-gen-dart is missing: dart pub global activate protoc_plugin" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"

# The well-known types (Timestamp, Duration) come from package:protobuf, and the google.rpc error details
# from package:grpc, so only Raindrop's own files are generated.
(cd "$PROTO" && protoc --dart_out=grpc:"$OUT" raindrop/v1/*.proto)

# The JSON descriptors are for reflection-based tooling this app does not use.
find "$OUT" -name '*.pbjson.dart' -delete

echo "Generated $(find "$OUT" -name '*.dart' | wc -l | tr -d ' ') files into ${OUT#"$CLIENT"/} from RaindropProto $(git -C "$PROTO" rev-parse --short HEAD 2>/dev/null || echo '(not a git checkout)')."
