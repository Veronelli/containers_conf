## Context

Este proyecto usa Alpine Linux como base para todos los contenedores y sigue una estructura por carpeta con Containerfile, compose.yaml, entrypoint script y configuración por variables de entorno. Postfix y Dovecot deben convivir en un mismo contenedor compartiendo el spool de correo vía Maildir en `/var/mail`.

## Goals / Non-Goals

**Goals:**
- Un solo contenedor corra Postfix (SMTP puerto 25) y Dovecot (IMAP puerto 143)
- Postfix reciba correos y los entregue en Maildirs locales
- Dovecot lea los Maildirs y los exponga por IMAP con autenticación PAM
- Configuración 100% por variables de entorno, sin valores hardcodeados
- Ejecución como usuario no-root

**Non-Goals:**
- SMTP submission (puerto 587) con autenticación — solo recepción en puerto 25
- TLS/SSL en IMAP o SMTP en esta primera iteración
- Soporte multi-dominio o usuarios virtuales
- Envío de correos hacia afuera (relay)
- Múltiples usuarios con dominios distintos — un dominio, un usuario por ahora

## Decisions

### Supervisor para múltiples servicios
Usamos `supervisord` para ejecutar Postfix y Dovecot en un solo contenedor. Es liviano, probado y viene empaquetado en Alpine. Alternativa considerada: `s6-overlay`, descartada por ser más compleja y no aportar beneficios para solo dos procesos.

### Entrega de correo vía LMTP
Postfix entrega a Dovecot usando el protocolo LMTP en lugar de escribir directamente al Maildir. Esto asegura que Dovecot maneje índices y quotas correctamente. Alternativa considerada: entrega directa al Maildir vía `virtual_mailbox`, descartada porque Dovecot no tendría visibilidad de los cambios en tiempo real y los índices se desincronizarían.

### Autenticación vía PAM
Dovecot autentica contra usuarios del sistema usando PAM. Cada usuario del contenedor con Maildir en `/var/mail/<usuario>` se convierte automáticamente en un buzón accesible. Alternativa considerada: passwd file estático con Dovecot dict, descartada porque duplicaría la gestión de credenciales.

### Creación de usuarios en entrypoint
El script `docker-entrypoint.sh` lee `MAIL_USER` y `MAIL_PASS`, crea el usuario del sistema con `adduser`, configura el Maildir y genera las configuraciones con `envsubst` antes de lanzar supervisord.

### Maildir como formato de almacenamiento
Formato estándar Maildir (`~/Maildir/`) para cada usuario. Dovecot y Postfix lo soportan nativamente sin configuración adicional. Cada correo es un archivo independiente, lo que evita locks en NFS y simplifica backups.

## Risks / Trade-offs

- [Postfix+Dovecot en un contenedor] → No escala horizontalmente, pero para el caso de uso (desarrollo/testing) es aceptable. Si se necesita escalar, migrar a contenedores separados.
- [Puerto 25 privilegiado] → Requiere `CAP_NET_BIND_SERVICE` o ejecutar el entrypoint como root y luego bajar privilegios con `su-exec`. Usaremos la segunda opción.
- [Usuarios del sistema] → Solo soporta un usuario por contenedor (definido por MAIL_USER). Para múltiples usuarios en el futuro haría falta un script de provisioning más complejo.
