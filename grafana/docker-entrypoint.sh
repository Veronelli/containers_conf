#!/usr/bin/env sh
set -eu

export GF_DATABASE_TYPE="${GRAFANA_DATABASE_TYPE:-mysql}"
export GF_DATABASE_HOST="${GRAFANA_DATABASE_HOST:-mariadb:3306}"
export GF_DATABASE_NAME="${GRAFANA_DATABASE_NAME:-grafana}"
export GF_DATABASE_USER="${GRAFANA_DATABASE_USER:-grafana}"
export GF_DATABASE_PASSWORD="${GRAFANA_DATABASE_PASSWORD:-change-me-password}"
export GF_DATABASE_SSL_MODE="${GRAFANA_DATABASE_SSL_MODE:-disable}"


PROVISIONING_DIR="/etc/grafana/provisioning"
TEMPLATE_DIR="${PROVISIONING_DIR}"

if command -v envsubst >/dev/null 2>&1; then
  mkdir -p "${PROVISIONING_DIR}/datasources" "${PROVISIONING_DIR}/dashboards"

  for template in "${TEMPLATE_DIR}/datasources/"*.yaml.template; do
    [ -f "$template" ] || continue
    output="${PROVISIONING_DIR}/datasources/$(basename "$template" .template)"
    envsubst < "$template" > "$output"
  done

  for template in "${TEMPLATE_DIR}/dashboards/"*.yaml.template; do
    [ -f "$template" ] || continue
    output="${PROVISIONING_DIR}/dashboards/$(basename "$template" .template)"
    envsubst < "$template" > "$output"
  done
fi

exec /run.sh "$@"
