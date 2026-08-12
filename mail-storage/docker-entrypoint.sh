#!/usr/bin/env sh
set -eu

envsubst < /etc/postfix/main.cf.template > /etc/postfix/main.cf
envsubst < /etc/dovecot/dovecot.conf.template > /etc/dovecot/dovecot.conf

install -d -m 0755 /etc/pam.d /var/mail
chown root:mail /var/mail
chmod 2775 /var/mail
mkdir -p /run
rm -f /run/noip-duc.pid

NOIP_CONFIG_VALID=true
for variable in NOIP_USERNAME NOIP_PASSWORD NOIP_HOSTNAME; do
  case "${variable}" in
    NOIP_USERNAME) value=${NOIP_USERNAME:-} ;;
    NOIP_PASSWORD) value=${NOIP_PASSWORD:-} ;;
    NOIP_HOSTNAME) value=${NOIP_HOSTNAME:-} ;;
  esac
  if [ -z "${value}" ]; then
    printf 'No-IP DDNS configuration error: %s is required\n' "${variable}" >&2
    NOIP_CONFIG_VALID=false
  fi
done

NOIP_UPDATE_INTERVAL=${NOIP_UPDATE_INTERVAL:-5m}

dovecot -c /etc/dovecot/dovecot.conf -n >/dev/null
newaliases

dovecot -c /etc/dovecot/dovecot.conf -F &
DOVECOT_PID=$!
postfix start-fg &
POSTFIX_PID=$!

start_noip() {
  NOIP_HOSTNAMES="${NOIP_HOSTNAME}" \
  NOIP_CHECK_INTERVAL="${NOIP_UPDATE_INTERVAL}" \
  NOIP_LOG_LEVEL=info \
    /usr/local/bin/noip-duc &
  NOIP_PID=$!
  printf '%s\n' "${NOIP_PID}" > /run/noip-duc.pid
  printf 'No-IP DDNS client started for %s\n' "${NOIP_HOSTNAME}"
}

NOIP_PID=
if [ "${NOIP_CONFIG_VALID}" = true ]; then
  start_noip
else
  printf '%s\n' 'No-IP DDNS client was not started; mail services remain available' >&2
fi

cleanup() {
  kill "${DOVECOT_PID}" "${POSTFIX_PID}" ${NOIP_PID:-} 2>/dev/null || true
  wait "${DOVECOT_PID}" 2>/dev/null || true
  wait "${POSTFIX_PID}" 2>/dev/null || true
  wait "${NOIP_PID:-}" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

while kill -0 "${DOVECOT_PID}" 2>/dev/null && kill -0 "${POSTFIX_PID}" 2>/dev/null; do
  if [ "${NOIP_CONFIG_VALID}" = true ] && ! kill -0 "${NOIP_PID}" 2>/dev/null; then
    wait "${NOIP_PID}" 2>/dev/null || true
    printf '%s\n' 'No-IP DDNS client exited; retrying in 5 seconds' >&2
    rm -f /run/noip-duc.pid
    sleep 5
    start_noip
  fi
  sleep 1
done

if ! kill -0 "${DOVECOT_PID}" 2>/dev/null; then
  wait "${DOVECOT_PID}"
  exit $?
fi

wait "${POSTFIX_PID}"
