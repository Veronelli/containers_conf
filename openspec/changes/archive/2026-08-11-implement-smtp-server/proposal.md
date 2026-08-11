## Why

Necesitamos que la composición `mail-storage` pase de ser un esqueleto pasivo a un servidor de correo funcional con capacidad SMTP. Actualmente solo expone puertos y monta volúmenes sin ningún software de mail — queremos instalar Postfix para recibir y enviar correos, cerrando la brecha de transporte.

## What Changes

- Se modifica `mail-storage/` para incluir Postfix como MTA
- Containerfile instala `postfix` vía apk
- compose.yaml expone el puerto SMTP (25) sin TLS
- Configuración SMTP vía variables de entorno (hostname, dominio, redes permitidas)
- Entrypoint genera `main.cf` desde template con envsubst y arranca Postfix
- Sin servidor IMAP/POP3 — solo transporte SMTP
- Se preservan volúmenes, límites de recursos y ejecución non-root existentes

## Capabilities

### New Capabilities

<!-- Ninguna. No se crea una nueva composición. -->

### Modified Capabilities

- `mail-storage`: Se agrega servicio SMTP Postfix al contenedor existente — recepción y relay de correos, sin TLS, configurable por variables de entorno

## Impact

- Archivos modificados dentro de `mail-storage/`: Containerfile, compose.yaml, .env.example, docker-entrypoint.sh, .gitignore
- Puerto 25 expuesto en el host (adicional al 143 existente)
- Sin impacto en otras composiciones
