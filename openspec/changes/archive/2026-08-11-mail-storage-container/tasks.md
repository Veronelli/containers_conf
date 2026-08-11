## 1. Estructura del proyecto

- [x] 1.1 Crear carpeta `mail-storage/` con `.gitignore` que ignore `.env`, `data/` y `*.log`
- [x] 1.2 Crear `.env.example` con variables de entorno: nombre de imagen, nombre de contenedor, puerto, límites de CPU y memoria

## 2. Containerfile

- [x] 2.1 Escribir `Containerfile` basado en `alpine:latest`, copiar `docker-entrypoint.sh`, establecer `USER` no-root (`mail`), sin instalar software de mail

## 3. Entrypoint

- [x] 3.1 Escribir `docker-entrypoint.sh` básico con `#!/usr/bin/env sh`, `set -eu`, y `exec tail -f /dev/null` como placeholder para mantener el contenedor en ejecución

## 4. Orquestación

- [x] 4.1 Crear `compose.yaml` con el servicio `mail-storage`, mapeo de puerto configurable, volumen `./data:/data`, `env_file: ./.env`, `cpus: ${MAIL_STORAGE_CPU_LIMIT:-0.5}`, `mem_limit: ${MAIL_STORAGE_MEMORY_LIMIT:-512m}`, `security_opt: no-new-privileges:true`
- [x] 4.2 Crear `run-compose.sh` que cargue `.env`, exporte las variables y ejecute `docker compose`

## 5. Documentación

- [x] 5.1 Escribir `README.md` con propósito, arquitectura, prerequisitos, quick-start, tabla de variables de entorno, y notas de seguridad

## 6. Verificación

- [x] 6.1 Construir la imagen y levantar el contenedor
- [x] 6.2 Verificar que los límites de CPU y memoria se aplican correctamente
- [x] 6.3 Verificar que el contenedor se ejecuta como usuario no-root
