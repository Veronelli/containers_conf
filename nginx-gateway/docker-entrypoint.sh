#!/usr/bin/env sh
set -eu

RUNTIME_DIR=/tmp/nginx-gateway
CONF_DIR=${RUNTIME_DIR}/conf.d
AUTH_DIR=${RUNTIME_DIR}/auth

die() {
    echo "nginx-gateway: $*" >&2
    exit 1
}

valid_domain() {
    printf '%s' "$1" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$'
}

valid_upstream() {
    case "$1" in
        *:*) host=${1%:*}; port=${1##*:} ;;
        *) return 1 ;;
    esac
    [ -n "$host" ] && printf '%s' "$host" | grep -Eq '^[A-Za-z0-9._-]+$' || return 1
    printf '%s' "$port" | grep -Eq '^[0-9]+$' || return 1
    [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

route_id() {
    printf '%s' "$1" | sed 's/-/_H_/g; s/\./_D_/g' | tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
}

environment_value() {
    printenv "$1" 2>/dev/null || true
}

write_main_config() {
    cat > "${RUNTIME_DIR}/nginx.conf" <<EOF
pid ${RUNTIME_DIR}/nginx.pid;
error_log /dev/stderr notice;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /dev/stdout;
    sendfile on;
    client_body_temp_path ${RUNTIME_DIR}/client_temp;
    proxy_temp_path ${RUNTIME_DIR}/proxy_temp;
    fastcgi_temp_path ${RUNTIME_DIR}/fastcgi_temp;
    uwsgi_temp_path ${RUNTIME_DIR}/uwsgi_temp;
    scgi_temp_path ${RUNTIME_DIR}/scgi_temp;
    include ${CONF_DIR}/*.conf;
}
EOF

    cat > "${CONF_DIR}/00-default.conf" <<EOF
server {
    listen ${NGINX_HTTP_PORT};
    server_name _;

    location = /_health {
        access_log off;
        return 200;
    }

    location / {
        return 400;
    }
}
EOF
}

write_route() {
    domain=$1
    upstream=$2
    policy=$3
    id=$(route_id "$domain")
    route_conf="${CONF_DIR}/${id}.conf"

    {
        printf 'server {\n'
        printf '    listen %s;\n' "$NGINX_HTTP_PORT"
        printf '    server_name %s;\n' "$domain"

        case "$policy" in
            public)
                ;;
            allowlist)
                allowed=$(environment_value "NGINX_ROUTE_${id}_ALLOWLIST")
                [ -n "$allowed" ] || die "route ${domain} requires NGINX_ROUTE_${id}_ALLOWLIST"
                old_ifs=$IFS
                IFS=,
                set -- $allowed
                IFS=$old_ifs
                for network in "$@"; do
                    printf '%s' "$network" | grep -Eq '^[0-9A-Fa-f:.]+(/[0-9]{1,3})?$' || die "route ${domain} has invalid allowed network: ${network}"
                    printf '    allow %s;\n' "$network"
                done
                printf '    deny all;\n'
                ;;
            basic-auth)
                credentials=$(environment_value "NGINX_ROUTE_${id}_BASIC_AUTH")
                printf '%s' "$credentials" | grep -Eq '^[^:[:space:]]+:[^[:space:]]+$' || die "route ${domain} requires NGINX_ROUTE_${id}_BASIC_AUTH as username:password-hash"
                printf '%s\n' "$credentials" > "${AUTH_DIR}/${id}"
                chmod 600 "${AUTH_DIR}/${id}"
                printf '    auth_basic "Restricted";\n'
                printf '    auth_basic_user_file %s;\n' "${AUTH_DIR}/${id}"
                ;;
            *)
                die "route ${domain} uses unsupported access policy: ${policy}"
                ;;
        esac

        cat <<'EOF'
    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
EOF
        printf '        proxy_pass http://%s;\n' "$upstream"
        printf '    }\n'
        printf '}\n'
    } > "$route_conf"
}

[ -n "${NGINX_HTTP_PORT:-}" ] || die "NGINX_HTTP_PORT is required"
printf '%s' "$NGINX_HTTP_PORT" | grep -Eq '^[0-9]+$' || die "NGINX_HTTP_PORT must be numeric"
[ "$NGINX_HTTP_PORT" -ge 1024 ] && [ "$NGINX_HTTP_PORT" -le 65535 ] || die "NGINX_HTTP_PORT must be between 1024 and 65535 for non-root execution"
[ -n "${NGINX_ROUTES:-}" ] || die "NGINX_ROUTES is required"

rm -rf "$RUNTIME_DIR"
mkdir -p "$CONF_DIR" "$AUTH_DIR" "${RUNTIME_DIR}/client_temp" "${RUNTIME_DIR}/proxy_temp" "${RUNTIME_DIR}/fastcgi_temp" "${RUNTIME_DIR}/uwsgi_temp" "${RUNTIME_DIR}/scgi_temp"
write_main_config

route_count=0
while IFS='|' read -r domain upstream policy extra; do
    [ -z "${domain}${upstream}${policy}${extra}" ] && continue
    [ -z "${extra:-}" ] || die "invalid route format; expected domain|service:port|policy"
    valid_domain "$domain" || die "invalid route domain: ${domain}"
    valid_upstream "$upstream" || die "invalid route upstream for ${domain}: ${upstream}"
    case "$policy" in public|allowlist|basic-auth) ;; *) die "invalid route policy for ${domain}: ${policy}" ;; esac
    write_route "$domain" "$upstream" "$policy"
    route_count=$((route_count + 1))
done <<EOF
${NGINX_ROUTES}
EOF

[ "$route_count" -gt 0 ] || die "NGINX_ROUTES must contain at least one route"
nginx -t -c "${RUNTIME_DIR}/nginx.conf"
exec "$@"
