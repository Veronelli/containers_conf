#!/usr/bin/env sh
set -eu

envsubst < /etc/postfix/main.cf.template > /etc/postfix/main.cf
newaliases

exec postfix start-fg
