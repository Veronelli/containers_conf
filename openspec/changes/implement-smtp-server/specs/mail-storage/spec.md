## ADDED Requirements

### Requirement: SMTP server receives incoming mail
El sistema DEBE aceptar conexiones SMTP entrantes en el puerto 25 y almacenar los correos recibidos en el directorio de cola de Postfix.

#### Scenario: Client sends an email via SMTP
- **WHEN** un cliente externo se conecta al puerto 25 y envía un comando `MAIL FROM`, `RCPT TO` y `DATA` válidos
- **THEN** Postfix acepta el mensaje y lo encola para entrega local

### Requirement: SMTP server relays outgoing mail
El sistema DEBE permitir el envío de correos salientes a destinos externos a través de SMTP en el puerto 25.

#### Scenario: Outbound email is relayed
- **WHEN** un cliente autorizado envía un correo con destino a un dominio externo
- **THEN** Postfix intenta la entrega al servidor MX del dominio destino

### Requirement: No TLS enforcement
El sistema NO DEBE requerir ni ofrecer TLS en las conexiones SMTP entrantes o salientes. Las conexiones se manejan en texto plano.

#### Scenario: Plaintext SMTP connection accepted
- **WHEN** un cliente se conecta al puerto 25 sin iniciar STARTTLS
- **THEN** Postfix procesa los comandos SMTP normalmente sin negociar cifrado

### Requirement: No IMAP or POP3 service
El sistema NO DEBE incluir ni exponer servicios IMAP o POP3. Solo el servicio SMTP está disponible.

#### Scenario: IMAP port is not exposed
- **WHEN** se inspeccionan los puertos expuestos del contenedor
- **THEN** no hay ningún puerto IMAP (143) ni POP3 (110) en exposición

### Requirement: SMTP configuration via environment variables
La configuración SMTP de Postfix (hostname, dominio, redes permitidas) DEBE derivarse de variables de entorno definidas en `.env`. El `.env.example` DEBE documentar todas las variables SMTP nuevas.

#### Scenario: SMTP hostname configured via environment variable
- **WHEN** se define `SMTP_MYHOSTNAME=mail.example.com` en el `.env`
- **THEN** Postfix usa `mail.example.com` como su hostname en las cabeceras SMTP

#### Scenario: SMTP allowed networks configured via environment variable
- **WHEN** se define `SMTP_MYNETWORKS=192.168.1.0/24` en el `.env`
- **THEN** Postfix permite relay desde la red 192.168.1.0/24
