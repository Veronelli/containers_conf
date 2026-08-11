## Why

Necesitamos un contenedor base Alpine como punto de partida para almacenamiento de correos. El contenedor expone los puertos necesarios, aplica límites de recursos y se configura por variables de entorno, pero no incluye software de mail específico — es un esqueleto listo para que el usuario instale el servidor IMAP/POP3 que prefiera.

## What Changes

- Nuevo contenedor base Alpine con entrypoint básico
- Puertos expuestos configurables por variables de entorno
- Límite de CPU en 0.5 y memoria en 512MB por defecto
- Configuración 100% por variables de entorno, sin valores hardcodeados
- Containerfile, compose.yaml, .env.example, docker-entrypoint.sh, run-compose.sh y README.md siguiendo las convenciones del proyecto

## Capabilities

### New Capabilities

- `mail-storage`: Composición de contenedor base Alpine para almacenamiento de correos, con puertos expuestos, límites de recursos (CPU 0.5, memoria 512MB), configuración por variables de entorno, y entrypoint básico. No incluye software de mail — es un esqueleto para instalar el servidor deseado.

### Modified Capabilities

<!-- Ninguna capacidad existente se modifica. -->

## Impact

- Nueva carpeta `mail-storage/` en la raíz del proyecto con Containerfile, compose.yaml, .env.example, scripts y configuración
- Sin impacto en otros contenedores existentes
