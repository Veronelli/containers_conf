## Why

El contenedor `mail-storage` necesita un nombre DNS dinámico para que los servicios de correo sean accesibles aunque cambie la dirección IP pública del host. Actualmente no existe un cliente DDNS integrado, por lo que la actualización del registro No-IP depende de procesos externos y puede quedar desincronizada.

## What Changes

- Incorporar el cliente oficial `noip-duc` versión `3.3.0` en la imagen de `mail-storage` desde el archivo tarball proporcionado.
- Ejecutar el cliente DDNS dentro del contenedor junto con Postfix y Dovecot.
- Obtener usuario, contraseña y nombre de host DDNS exclusivamente mediante variables de entorno entregadas al contenedor.
- Documentar las nuevas variables y los requisitos de configuración en `.env.example` y `README.md`.
- Mantener el servicio funcional y supervisado cuando el cliente DDNS se detenga o falle, informando el estado mediante logs y health check apropiado.

## Capabilities

### New Capabilities

- `noip-ddns`: Actualización periódica del hostname No-IP desde el contenedor `mail-storage` usando credenciales y hostname provistos por entorno.

### Modified Capabilities

- `mail-storage`: El contenedor incorpora un proceso auxiliar DDNS y variables de configuración adicionales, sin cambiar los contratos SMTP/IMAP existentes.

## Impact

- `mail-storage/Containerfile`: descarga, instala y configura el cliente No-IP.
- `mail-storage/compose.yaml`: entrega las variables DDNS y conserva límites, volúmenes y seguridad existentes.
- `mail-storage/docker-entrypoint.sh`: inicia y supervisa el cliente junto con los servicios actuales.
- `mail-storage/.env.example` y `mail-storage/README.md`: documentan configuración, secretos y comportamiento operativo.
- El contenedor requerirá conectividad saliente HTTPS hacia No-IP. Las credenciales no deben incluirse en la imagen, el repositorio ni los logs.
