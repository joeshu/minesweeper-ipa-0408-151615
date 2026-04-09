#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 <owner> <repo> [run_id]"
  echo "Example: $0 joeshu minesweeper-ipa-0408-151615"
}

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

OWNER="$1"
REPO="$2"
RUN_ID="${3:-}"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Error: GITHUB_TOKEN is not set"
  echo "Set it first in Minis Environment Variables."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="/var/minis/workspace/gha_ipa_${REPO}_${STAMP}"
mkdir -p "$OUT_DIR"

RUNS_JSON="$OUT_DIR/runs.json"

curl -sSL \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?per_page=20" \
  -o "$RUNS_JSON"

LATEST_INFO="$(python3 - "$RUNS_JSON" <<'PY'
import json,sys
p=sys.argv[1]
d=json.load(open(p,'r',encoding='utf-8'))
runs=d.get('workflow_runs',[])
if not runs:
    print('ERR:no_runs')
    sys.exit(0)
r=runs[0]
print('OK')
print(r.get('run_number'))
print(r.get('id'))
print(r.get('status'))
print(r.get('conclusion'))
print((r.get('head_sha') or '')[:7])
print(r.get('html_url'))
PY
)"

FIRST_LINE="$(echo "$LATEST_INFO" | sed -n '1p')"
if [ "$FIRST_LINE" != "OK" ]; then
  echo "Error: cannot get workflow runs ($FIRST_LINE)"
  exit 1
fi

LATEST_RUN_NUMBER="$(echo "$LATEST_INFO" | sed -n '2p')"
LATEST_RUN_ID="$(echo "$LATEST_INFO" | sed -n '3p')"
LATEST_STATUS="$(echo "$LATEST_INFO" | sed -n '4p')"
LATEST_CONCLUSION="$(echo "$LATEST_INFO" | sed -n '5p')"
LATEST_SHA="$(echo "$LATEST_INFO" | sed -n '6p')"
LATEST_URL="$(echo "$LATEST_INFO" | sed -n '7p')"

echo "Latest run: #$LATEST_RUN_NUMBER id=$LATEST_RUN_ID status=$LATEST_STATUS conclusion=$LATEST_CONCLUSION sha=$LATEST_SHA"
echo "URL: $LATEST_URL"

if [ -z "$RUN_ID" ]; then
  # 优先用最新成功 run；否则回退到最近一个成功 run
  RUN_PICK="$(python3 - "$RUNS_JSON" <<'PY'
import json,sys
runs=json.load(open(sys.argv[1],'r',encoding='utf-8')).get('workflow_runs',[])
if not runs:
    print('ERR:no_runs')
    raise SystemExit
latest=runs[0]
if latest.get('status')=='completed' and latest.get('conclusion')=='success':
    print(latest.get('id'))
    raise SystemExit
for r in runs:
    if r.get('status')=='completed' and r.get('conclusion')=='success':
        print(r.get('id'))
        raise SystemExit
print('ERR:no_success_run')
PY
)"
  case "$RUN_PICK" in
    ERR:*)
      echo "Error: $RUN_PICK"
      exit 1
      ;;
    *) RUN_ID="$RUN_PICK" ;;
  esac
fi

echo "Using run_id=$RUN_ID"

ARTIFACTS_JSON="$OUT_DIR/artifacts.json"
curl -sSL \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/artifacts" \
  -o "$ARTIFACTS_JSON"

ARTIFACT_INFO="$(python3 - "$ARTIFACTS_JSON" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],'r',encoding='utf-8'))
arts=d.get('artifacts',[])
if not arts:
    print('ERR:no_artifacts')
    raise SystemExit
pick=None
for a in arts:
    n=(a.get('name') or '').lower()
    if 'ipa' in n:
        pick=a
        break
if pick is None:
    pick=arts[0]
print('OK')
print(pick.get('name') or '')
print(pick.get('size_in_bytes') or 0)
print(pick.get('archive_download_url') or '')
PY
)"

A1="$(echo "$ARTIFACT_INFO" | sed -n '1p')"
if [ "$A1" != "OK" ]; then
  echo "Error: cannot locate artifact ($A1)"
  exit 1
fi

ART_NAME="$(echo "$ARTIFACT_INFO" | sed -n '2p')"
ART_SIZE="$(echo "$ARTIFACT_INFO" | sed -n '3p')"
ART_URL="$(echo "$ARTIFACT_INFO" | sed -n '4p')"

echo "Artifact: $ART_NAME (${ART_SIZE} bytes)"

ZIP_PATH="$OUT_DIR/artifact.zip"

curl -sSL \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$ART_URL" -o "$ZIP_PATH"

unzip -o -q "$ZIP_PATH" -d "$OUT_DIR/unzipped"

IPA_PATH="$(find "$OUT_DIR/unzipped" -type f -name '*.ipa' | head -n 1 || true)"
if [ -z "$IPA_PATH" ]; then
  echo "Error: no .ipa file found in artifact"
  echo "Unzipped files:"
  find "$OUT_DIR/unzipped" -type f | sed -n '1,50p'
  exit 1
fi

IPA_BASE="$(basename "$IPA_PATH")"
TARGET="/var/minis/attachments/$IPA_BASE"
cp "$IPA_PATH" "$TARGET"

echo "Downloaded IPA: $TARGET"
echo "Minis URL: minis://attachments/$IPA_BASE"
