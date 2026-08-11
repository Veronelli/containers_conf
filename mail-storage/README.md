# Mail Storage Container

Contenedor base Alpine como punto de partida para almacenamiento de correos. Expone puertos configurables, aplica límites de recursos y se configura por variables de entorno. No incluye software de mail — es un esqueleto listo para instalar el servidor IMAP/POP3 que se necesite.

## Architecture

- Contenedor Alpine con entrypoint básico que mantiene el proceso en ejecución.
- Puerto expuesto configurable vía `MAIL_STORAGE_PORT`.
- Volumen persistente en `./data` para los buzones de correo.
- Ejecución como usuario no-root (`mail`) con `no-new-privileges:true`.

## Files

- `Containerfile`: basado en `alpine:latest`, copia el entrypoint y establece `USER mail`.
- `compose.yaml`: define el servicio, puerto, volumen, y límites de recursos.
- `.env.example`: plantilla de configuración documentada.
- `.env`: archivo de configuración en tiempo de ejecución (no se commitea).
- `docker-entrypoint.sh`: script de inicio básico que mantiene el contenedor en ejecución.
- `run-compose.sh`: wrapper que carga `.env` y ejecuta `docker compose`.

## Prerequisites

- Container runtime (Docker, Podman) instalado.
- Puerto libre para exponer el servicio.

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

4. Detener el contenedor:

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
| `MAIL_STORAGE_BIND_HOST` | Host de bind para el puerto | `0.0.0.0` |
| `MAIL_STORAGE_BIND_PORT` | Puerto en el host | `143` |
| `MAIL_STORAGE_PORT` | Puerto interno del contenedor | `143` |
| `MAIL_STORAGE_CPU_LIMIT` | Límite de CPU | `0.5` |
| `MAIL_STORAGE_MEMORY_LIMIT` | Límite de memoria | `512m` |

## Notes

- El contenedor corre como usuario `mail` (no-root).
- `no-new-privileges:true` está habilitado.
- CPU limitada a 0.5 cores y memoria a 512MB por defecto.
- El volumen `./data` persiste los datos entre reinicios.
- Este es un contenedor esqueleto — no incluye software de mail. Instalar y configurar Dovecot, Courier, u otro servidor IMAP/POP3 según necesidad.
