# Mail Storage Container

Contenedor Alpine con Postfix como MTA y Dovecot como servidor IMAP. Recibe y envía correos SMTP y permite leer buzones locales por IMAP, ambos en texto plano y sin TLS. Expone los puertos 25 y 143, aplica límites de recursos y se configura por variables de entorno.

## Architecture

- Contenedor Alpine con Postfix instalado y entrypoint que genera `main.cf` desde variables de entorno.
- Dovecot instalado en el mismo contenedor; el entrypoint genera su configuración y supervisa ambos procesos en foreground.
- Puerto SMTP (25) expuesto y configurable vía `SMTP_BIND_HOST` y `SMTP_BIND_PORT`.
- Puerto IMAP (143) expuesto y configurable vía `MAIL_STORAGE_BIND_HOST` y `MAIL_STORAGE_BIND_PORT`.
- Autenticación IMAP mediante PAM para usuarios locales y buzón mbox en `/var/mail/<usuario>` por defecto.
- Volumen persistente en `./data` para la cola de correos y datos de Postfix.
- El proceso master de Postfix corre como root (necesario para bindear puerto 25). Los procesos hijos usan `default_privs = nobody`.
- `no-new-privileges:true` habilitado.

## Files

- `Containerfile`: basado en `alpine:latest`, instala Postfix, Dovecot, PAM y `gettext`, y copia los templates de configuración.
- `dovecot.conf.template`: plantilla de configuración IMAP, PAM, mbox y TLS deshabilitado.
- `pam.dovecot`: política PAM local usada por Dovecot.
- `compose.yaml`: define el servicio, puertos, volumen, y límites de recursos.
- `main.cf.template`: plantilla de configuración de Postfix con variables de entorno.
- `.env.example`: plantilla de configuración documentada.
- `.env`: archivo de configuración en tiempo de ejecución (no se commitea).
- `docker-entrypoint.sh`: genera las configuraciones con `envsubst` y supervisa Postfix y Dovecot en foreground.
- `run-compose.sh`: wrapper que carga `.env` y ejecuta `docker compose`.
- `healthcheck-imap.sh`: ejecuta manualmente el mismo health check end-to-end usado por Compose.
- `healthcheck-container.sh`: runner interno que crea los fixtures, envía y lee un mensaje de prueba y limpia todo al finalizar.
- `compose.yaml`: ejecuta automáticamente el health check end-to-end y marca el servicio como `healthy` solo si SMTP e IMAP funcionan.

## Prerequisites

- Container runtime (Docker, Podman) instalado.
- Puertos 25 y 143 libres en el host.

## Quick start

1. Copiar `.env.example` a `.env` y revisar los valores:

   ```sh
   cp .env.example .env
   ```

2. Construir y levantar el contenedor:

   ```sh
   ./run-compose.sh up -d --build
   ```

3. Verificar que el contenedor está corriendo:

   ```sh
   ./run-compose.sh ps
   ```

   El estado `healthy` confirma que Postfix entregó un mensaje y Dovecot lo leyó mediante IMAP.

4. Verificar que los puertos SMTP e IMAP responden:

   ```sh
   nc -zv localhost 25
   nc -zv localhost 143
   ```

5. Ejecutar manualmente el mismo health check end-to-end con credenciales temporales:

   ```sh
   ./healthcheck-imap.sh
   ```

6. Detener el contenedor:

   ```sh
   ./run-compose.sh down
   ```

## Environment variables

| Variable | Description | Default |
|---|---|---|
| `MAIL_STORAGE_IMAGE_NAME` | Nombre de la imagen | `mail-storage` |
| `MAIL_STORAGE_IMAGE_TAG` | Tag de la imagen | `latest` |
| `MAIL_STORAGE_CONTAINER_NAME` | Nombre del contenedor | `mail-storage` |
| `MAIL_STORAGE_HOSTNAME` | Hostname del contenedor | `mail-storage` |
| `MAIL_STORAGE_RESTART_POLICY` | Política de reinicio | `unless-stopped` |
| `MAIL_STORAGE_PORT` | Puerto interno IMAP | `143` |
| `MAIL_STORAGE_BIND_HOST` | Host de binding IMAP | `0.0.0.0` |
| `MAIL_STORAGE_BIND_PORT` | Puerto IMAP en el host | `143` |
| `MAIL_STORAGE_CPU_LIMIT` | Límite de CPU | `0.5` |
| `MAIL_STORAGE_MEMORY_LIMIT` | Límite de memoria | `512m` |
| `MAIL_STORAGE_HEALTHCHECK_INTERVAL` | Intervalo del health check | `10s` |
| `MAIL_STORAGE_HEALTHCHECK_TIMEOUT` | Timeout del health check | `5s` |
| `MAIL_STORAGE_HEALTHCHECK_RETRIES` | Reintentos antes de marcar unhealthy | `3` |
| `MAIL_STORAGE_HEALTHCHECK_START_PERIOD` | Tiempo inicial antes de evaluar | `10s` |
| `MAIL_STORAGE_MAIL_LOCATION` | Ruta mbox del INBOX | `/var/mail/%{user}` |
| `MAIL_STORAGE_PAM_SERVICE` | Servicio PAM para Dovecot | `dovecot` |
| `MAIL_STORAGE_IMAP_TLS` | TLS IMAP | `no` |
| `SMTP_BIND_HOST` | Host de bind para SMTP | `0.0.0.0` |
| `SMTP_BIND_PORT` | Puerto SMTP en el host | `25` |
| `SMTP_MYHOSTNAME` | Hostname de Postfix | `mail.example.com` |
| `SMTP_MYDOMAIN` | Dominio de Postfix | `example.com` |
| `SMTP_MYDESTINATION` | Destinos locales aceptados | `$SMTP_MYHOSTNAME, localhost.$SMTP_MYDOMAIN, localhost` |
| `SMTP_MYNETWORKS` | Redes permitidas para relay | `127.0.0.0/8` |
| `IMAP_HEALTHCHECK_SENDER_PASSWORD` | Contraseña temporal de `test-sender` | `change-me-sender` |
| `IMAP_HEALTHCHECK_READER_PASSWORD` | Contraseña temporal de `test-reader` | `change-me-reader` |

## Security notes

- No se implementa TLS/STARTTLS — el tráfico SMTP e IMAP viaja en texto plano.
- No se configura autenticación SMTP (SASL).
- Las credenciales del health check son temporales y no deben contener secretos reales ni versionarse.
- Compose ejecuta automáticamente `healthcheck-container.sh` después del `start_period`; `healthcheck-imap.sh` permite repetirlo manualmente.
- `SMTP_MYNETWORKS` controla qué redes pueden hacer relay. Por defecto solo localhost.
- El proceso master de Postfix corre como root para bindear el puerto 25. Los procesos hijos usan `default_privs = nobody`.
- `no-new-privileges:true` está habilitado en la definición del servicio.
- CPU limitada a 0.5 cores y memoria a 512MB por defecto.

## Persistence

El volumen `./data` persiste la cola de correos y los datos de Postfix entre reinicios y recreaciones del contenedor. La estrategia de persistencia de buzones IMAP queda fuera de esta fase.
