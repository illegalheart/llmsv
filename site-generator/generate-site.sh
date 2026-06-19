#!/usr/bin/env bash
set -Eeuo pipefail

MODEL="${MODEL:-gemma4:e2b}"
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
export OLLAMA_HOST

mkdir -p /output

cleanup() {
  if [[ -n "${OLLAMA_PID:-}" ]]; then
    kill "$OLLAMA_PID" 2>/dev/null || true
    wait "$OLLAMA_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

ollama serve > /tmp/ollama.log 2>&1 &
OLLAMA_PID=$!

for _ in {1..60}; do
  if curl --silent --fail "http://${OLLAMA_HOST}/api/tags" >/dev/null; then
    break
  fi
  sleep 1
done

if ! curl --silent --fail "http://${OLLAMA_HOST}/api/tags" >/dev/null; then
  cat /tmp/ollama.log >&2
  exit 1
fi

echo "Pulling ${MODEL}."
ollama pull "$MODEL"

jq -n \
  --arg model "$MODEL" \
  --rawfile prompt /app/prompt.txt \
  '{
    model: $model,
    prompt: $prompt,
    stream: false,
    think: false,
    options: {
      temperature: 0.25,
      num_ctx: 8192
    },
    format: {
      type: "object",
      properties: {
        html: {type: "string"},
        design_summary: {type: "string"}
      },
      required: ["html", "design_summary"]
    }
  }' > /tmp/request.json

curl --silent --show-error --fail \
  --max-time 1200 \
  --header 'Content-Type: application/json' \
  --data-binary @/tmp/request.json \
  "http://${OLLAMA_HOST}/api/generate" \
  > /tmp/response.json

jq -er '.response | fromjson | .html' /tmp/response.json > /output/index.html
jq -er '.response | fromjson | .design_summary' /tmp/response.json > /output/design-summary.txt
jq -n \
  --arg model "$MODEL" \
  --arg generated_at "$(date -u +%FT%TZ)" \
  '{model: $model, generated_at: $generated_at}' \
  > /output/metadata.json

echo "Website generated successfully."
