#!/usr/bin/env sh
set -eu

SENDER_PASSWORD=${IMAP_HEALTHCHECK_SENDER_PASSWORD:?Set IMAP_HEALTHCHECK_SENDER_PASSWORD}
READER_PASSWORD=${IMAP_HEALTHCHECK_READER_PASSWORD:?Set IMAP_HEALTHCHECK_READER_PASSWORD}

cleanup() {
  deluser test-sender >/dev/null 2>&1 || true
  deluser test-reader >/dev/null 2>&1 || true
  rm -f /var/mail/test-sender /var/mail/test-reader
}

trap cleanup EXIT INT TERM

cleanup
adduser -D -s /sbin/nologin test-sender >/dev/null
adduser -D -s /sbin/nologin test-reader >/dev/null
printf 'test-sender:%s\n' "${SENDER_PASSWORD}" | chpasswd >/dev/null
printf 'test-reader:%s\n' "${READER_PASSWORD}" | chpasswd >/dev/null

{
  sleep 1
  printf 'EHLO healthcheck\r\n'
  sleep 1
  printf 'MAIL FROM:<test-sender@mail.example.com>\r\n'
  sleep 1
  printf 'RCPT TO:<test-reader@mail.example.com>\r\n'
  sleep 1
  printf 'DATA\r\n'
  sleep 1
  printf 'From: test-sender@mail.example.com\r\nTo: test-reader@mail.example.com\r\nSubject: test\r\n\r\nIMAP health check\r\n.\r\n'
  sleep 1
  printf 'QUIT\r\n'
} | nc -w 10 127.0.0.1 25 >/dev/null

sleep 2

response=$(sh -s <<'EOF'
set -eu
auth=$(printf '\0%s\0%s' test-reader "${IMAP_HEALTHCHECK_READER_PASSWORD}" | base64 | tr -d '\n')
{
  sleep 1
  printf 'a001 AUTHENTICATE PLAIN %s\r\n' "${auth}"
  sleep 1
  printf 'a002 SELECT INBOX\r\n'
  sleep 1
  printf 'a003 SEARCH SUBJECT test\r\n'
  sleep 1
  printf 'a004 FETCH 1 BODY[HEADER.FIELDS (FROM SUBJECT)]\r\n'
  sleep 1
  printf 'a005 LOGOUT\r\n'
} | nc -w 10 127.0.0.1 143
EOF
)

case "${response}" in
  *'test-sender@mail.example.com'*'Subject: test'*)
    printf '%s\n' 'IMAP health check passed'
    ;;
  *)
    printf '%s\n' 'IMAP health check failed: test message was not readable' >&2
    exit 1
    ;;
esac
