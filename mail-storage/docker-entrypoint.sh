#!/usr/bin/env sh
set -eu

envsubst < /etc/postfix/main.cf.template > /etc/postfix/main.cf
envsubst < /etc/dovecot/dovecot.conf.template > /etc/dovecot/dovecot.conf

install -d -m 0755 /etc/pam.d /var/mail
chown root:mail /var/mail
chmod 2775 /var/mail

dovecot -c /etc/dovecot/dovecot.conf -n >/dev/null
newaliases

dovecot -c /etc/dovecot/dovecot.conf -F &
DOVECOT_PID=$!
postfix start-fg &
POSTFIX_PID=$!

cleanup() {
  kill "${DOVECOT_PID}" "${POSTFIX_PID}" 2>/dev/null || true
  wait "${DOVECOT_PID}" 2>/dev/null || true
  wait "${POSTFIX_PID}" 2>/dev/null || true
}

trap cleanup INT TERM EXIT

while kill -0 "${DOVECOT_PID}" 2>/dev/null && kill -0 "${POSTFIX_PID}" 2>/dev/null; do
  sleep 1
done

if ! kill -0 "${DOVECOT_PID}" 2>/dev/null; then
  wait "${DOVECOT_PID}"
  exit $?
fi

wait "${POSTFIX_PID}"
