## Why

La composición `mail-storage` ya recibe y envía correo mediante Postfix, pero los usuarios todavía no pueden acceder a sus buzones. Necesitamos agregar acceso IMAP reutilizando el mismo contenedor y el almacenamiento local de correo, con autenticación PAM y sin introducir TLS ni una estrategia de volúmenes en esta etapa.

## What Changes

- Instalar Dovecot en el `mail-storage` existente junto con Postfix.
- Ejecutar Dovecot para servir IMAP plano en el puerto interno 143 y publicar el binding configurable correspondiente.
- Configurar Dovecot para leer los buzones locales que Postfix entrega y permitir autenticación mediante PAM.
- Generar la configuración de Dovecot desde variables de entorno y documentar los valores de ejemplo en `.env.example`.
- Ajustar el entrypoint para inicializar y supervisar Postfix y Dovecot dentro del mismo contenedor.
- Incorporar un health check end-to-end con los usuarios PAM temporales `test-sender` y `test-reader`: enviar un mensaje con asunto `test` a `test-reader@mail.example.com`, leerlo por IMAP y eliminar ambos fixtures al finalizar.
- Ejecutar ese health check automáticamente desde `compose.yaml` al levantar el servicio y marcarlo como `healthy` solo cuando el flujo completo sea exitoso.
- **BREAKING** Mantener IMAP sin TLS/STARTTLS: no se habilitan certificados ni cifrado en este cambio.
- No agregar ni modificar volúmenes para IMAP; la persistencia y el diseño final del almacenamiento quedan fuera de alcance.

## Capabilities

### New Capabilities

<!-- No se crea una composición nueva; el acceso IMAP modifica el contrato existente de mail-storage. -->

### Modified Capabilities

- `mail-storage`: Reemplazar la restricción de solo SMTP por un servicio IMAP en el puerto 143, con autenticación PAM y sin TLS.

## Impact

- Archivos afectados dentro de `mail-storage/`: `Containerfile`, `compose.yaml`, `.env.example`, `docker-entrypoint.sh` y `README.md`.
- Nueva dependencia de imagen: paquete Dovecot y sus módulos de autenticación PAM.
- El proceso del contenedor deberá arrancar y mantener activos Postfix y Dovecot.
- Los clientes IMAP necesitarán credenciales correspondientes a usuarios reconocidos por PAM en el contenedor.
- El health check usará credenciales temporales fuera de Git y deberá limpiar los usuarios fixture aunque la validación falle.
- No se modifica el puerto SMTP 25 ni su configuración existente.
