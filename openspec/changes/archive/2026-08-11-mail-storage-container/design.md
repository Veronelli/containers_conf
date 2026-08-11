## Context

El proyecto usa Alpine Linux como base, sigue una estructura por carpeta con Containerfile, compose.yaml, docker-entrypoint.sh y configuración por variables de entorno. El contenedor es un esqueleto base — no incluye software de mail específico. El usuario debe agregar el servidor IMAP/POP3 que necesite.

## Goals / Non-Goals

**Goals:**
- Contenedor base Alpine con entrypoint básico
- Puertos expuestos configurables vía `.env`
- Límites de recursos por defecto: CPU 0.5, memoria 512MB
- Ejecución como usuario no-root con `no-new-privileges:true`
- Volumen persistente para datos

**Non-Goals:**
- Instalar Dovecot, Postfix, o cualquier software de mail específico
- TLS/SSL, autenticación, o protocolos de mail
- Configuración de buzones o usuarios

## Decisions

### Alpine como base sin paquetes de mail
El Containerfile parte de `alpine:latest` sin instalar software de mail. El entrypoint es un script mínimo que ejecuta `tail -f /dev/null` como placeholder, permitiendo que el contenedor se mantenga en ejecución mientras el usuario agrega el software que necesite.

### Puertos genéricos configurables
El compose.yaml expone un puerto genérico configurable vía `MAIL_STORAGE_PORT`, sin asumir IMAP (143), POP3 (110), ni ningún protocolo específico. El usuario define el puerto según el software que instale.

### Volumen persistente genérico
Se monta `./data:/data` como volumen de datos genérico. El usuario decide la estructura interna según el software que agregue.

## Risks / Trade-offs

- [Esqueleto sin software] → El contenedor no hace nada útil por sí solo. Es responsabilidad del usuario instalar y configurar el servidor de mail que necesite.
- [Puerto genérico] → Si el usuario necesita múltiples puertos (IMAP + POP3 + submission), deberá modificar el compose.yaml manualmente.
