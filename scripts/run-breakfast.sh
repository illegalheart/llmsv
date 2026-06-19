#!/usr/bin/env bash
set -Eeuo pipefail

MODEL="${MODEL:-gemma4:e2b}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
export OLLAMA_HOST

mkdir -p /results

cleanup() {
  if [[ -n "${OLLAMA_PID:-}" ]]; then
    kill "$OLLAMA_PID" 2>/dev/null || true
    wait "$OLLAMA_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Ollama server を起動します。"
ollama serve > /tmp/ollama.log 2>&1 &
OLLAMA_PID=$!

for _ in {1..60}; do
  if curl --silent --fail "http://${OLLAMA_HOST}/api/tags" >/dev/null; then
    break
  fi
  sleep 1
done

if ! curl --silent --fail "http://${OLLAMA_HOST}/api/tags" >/dev/null; then
  echo "Ollama server の起動に失敗しました。" >&2
  cat /tmp/ollama.log >&2
  exit 1
fi

echo "ollama run ${MODEL} を実行します。"
ollama run "$MODEL" < /app/prompt.txt | tee /results/answer.txt
jq -n \
  --arg model "$MODEL" \
  --arg generated_at "$(date -u +%FT%TZ)" \
  '{model: $model, generated_at: $generated_at}' \
  > /results/metadata.json
