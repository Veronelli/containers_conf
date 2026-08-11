## Purpose

Proveer un servidor de correo completo con SMTP (Postfix) e IMAP (Dovecot) que permita recibir correos y que clientes lean sus buzones autenticándose con usuario y contraseña.

## ADDED Requirements

### Requirement: Recepción de correos por SMTP
El sistema SHALL aceptar correos entrantes por el puerto 25 usando el protocolo SMTP.

#### Scenario: Recepción de un correo dirigido a un dominio local
- **WHEN** un remitente externo envía un correo a `usuario@dominio-local` por el puerto 25
- **THEN** Postfix acepta el correo y lo entrega en el buzón del usuario mediante Dovecot

### Requirement: Autenticación de usuarios
El sistema SHALL autenticar usuarios por nombre de usuario y contraseña antes de permitir el acceso IMAP.

#### Scenario: Login exitoso con credenciales correctas
- **WHEN** un cliente IMAP se conecta con usuario y contraseña válidos
- **THEN** Dovecot permite el acceso al buzón del usuario

#### Scenario: Login rechazado con credenciales incorrectas
- **WHEN** un cliente IMAP se conecta con usuario o contraseña inválidos
- **THEN** Dovecot rechaza la autenticación

### Requirement: Acceso IMAP a buzones
El sistema SHALL exponer el servicio IMAP en el puerto 143 para que clientes lean, organicen y eliminen correos de sus buzones.

#### Scenario: Cliente lista los correos del buzón
- **WHEN** un cliente IMAP autenticado solicita la lista de mensajes en INBOX
- **THEN** Dovecot devuelve los mensajes disponibles con sus metadatos

#### Scenario: Cliente lee un correo específico
- **WHEN** un cliente IMAP autenticado solicita el contenido de un mensaje por su ID
- **THEN** Dovecot devuelve el contenido completo del mensaje

### Requirement: Configuración por variables de entorno
El sistema SHALL aceptar toda configuración relevante mediante variables de entorno sin hardcodear valores.

#### Scenario: Configuración del dominio
- **WHEN** se inicia el contenedor con la variable `MAIL_DOMAIN` definida
- **THEN** Postfix y Dovecot usan ese dominio para rutear y autenticar correos

#### Scenario: Configuración de usuarios
- **WHEN** se inicia el contenedor con variables `MAIL_USER` y `MAIL_PASS` definidas
- **THEN** se crea automáticamente un usuario del sistema con ese nombre y contraseña que puede autenticarse y recibir correos

### Requirement: Seguridad del contenedor
El sistema SHALL ejecutar los servicios como usuario no-root y aplicar restricciones de seguridad estándar.

#### Scenario: Verificación de usuario no-root
- **WHEN** se consulta el usuario que ejecuta los procesos de Postfix y Dovecot dentro del contenedor
- **THEN** ninguno de los procesos corre como root
