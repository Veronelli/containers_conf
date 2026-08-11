# Mail Storage Container

Contenedor Alpine con Postfix como MTA. Recibe y envía correos SMTP en texto plano, sin TLS. Expone el puerto 25, aplica límites de recursos y se configura por variables de entorno.

## Architecture

- Contenedor Alpine con Postfix instalado y entrypoint que genera `main.cf` desde variables de entorno.
- Puerto SMTP (25) expuesto y configurable vía `SMTP_BIND_HOST` y `SMTP_BIND_PORT`.
- Volumen persistente en `./data` para la cola de correos y datos de Postfix.
- El proceso master de Postfix corre como root (necesario para bindear puerto 25). Los procesos hijos usan `default_privs = nobody`.
- `no-new-privileges:true` habilitado.

## Files

- `Containerfile`: basado en `alpine:latest`, instala `postfix` y `gettext`, copia el entrypoint y el template de configuración.
- `compose.yaml`: define el servicio, puertos, volumen, y límites de recursos.
- `main.cf.template`: plantilla de configuración de Postfix con variables de entorno.
- `.env.example`: plantilla de configuración documentada.
- `.env`: archivo de configuración en tiempo de ejecución (no se commitea).
- `docker-entrypoint.sh`: genera `main.cf` con `envsubst` y arranca Postfix en foreground.
- `run-compose.sh`: wrapper que carga `.env` y ejecuta `docker compose`.

## Prerequisites

- Container runtime (Docker, Podman) instalado.
- Puerto 25 libre en el host.

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

4. Verificar que el puerto SMTP responde:

   ```sh
   nc -zv localhost 25
   ```

5. Detener el contenedor:

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
| `MAIL_STORAGE_CPU_LIMIT` | Límite de CPU | `0.5` |
| `MAIL_STORAGE_MEMORY_LIMIT` | Límite de memoria | `512m` |
| `SMTP_BIND_HOST` | Host de bind para SMTP | `0.0.0.0` |
| `SMTP_BIND_PORT` | Puerto SMTP en el host | `25` |
| `SMTP_MYHOSTNAME` | Hostname de Postfix | `mail.example.com` |
| `SMTP_MYDOMAIN` | Dominio de Postfix | `example.com` |
| `SMTP_MYDESTINATION` | Destinos locales aceptados | `$SMTP_MYHOSTNAME, localhost.$SMTP_MYDOMAIN, localhost` |
| `SMTP_MYNETWORKS` | Redes permitidas para relay | `127.0.0.0/8` |

## Security notes

- No se implementa TLS/STARTTLS — el tráfico SMTP viaja en texto plano.
- No se configura autenticación SMTP (SASL).
- `SMTP_MYNETWORKS` controla qué redes pueden hacer relay. Por defecto solo localhost.
- El proceso master de Postfix corre como root para bindear el puerto 25. Los procesos hijos usan `default_privs = nobody`.
- `no-new-privileges:true` está habilitado en la definición del servicio.
- CPU limitada a 0.5 cores y memoria a 512MB por defecto.

## Persistence

El volumen `./data` persiste la cola de correos y los datos de Postfix entre reinicios y recreaciones del contenedor.
