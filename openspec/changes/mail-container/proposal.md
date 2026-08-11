## Why

Necesitamos un contenedor auto-contenido que ofrezca servicios SMTP e IMAP para enviar y recibir correos. Los clientes deben poder autenticarse con usuario y contraseña para leer sus emails. Esto permite tener un entorno de mail local para desarrollo, testing, o despliegues pequeños sin depender de servicios externos.

## What Changes

- Nuevo contenedor con Postfix como MTA (SMTP) y Dovecot como servidor IMAP
- Recepción de correos entrantes vía SMTP en el puerto 25
- Autenticación de usuarios con usuario y contraseña contra cuentas del sistema
- Acceso IMAP para clientes de correo en puerto 143 (o 993 con TLS)
- Configuración basada en variables de entorno sin hardcodear valores
- Containerfile, compose.yaml y scripts helper siguiendo las convenciones del proyecto

## Capabilities

### New Capabilities

- `mail-server`: Composición de contenedor que ejecuta Postfix (SMTP) y Dovecot (IMAP) con autenticación de usuarios vía sistema, configuración por variables de entorno, y entrada de correos por puerto 25.

### Modified Capabilities

<!-- Ninguna capacidad existente se modifica. -->

## Impact

- Nueva carpeta `mail-server/` en la raíz del proyecto con Containerfile, compose.yaml, `.env.example`, scripts y configuración
- Sin impacto en otros contenedores existentes
