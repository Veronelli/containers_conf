## Purpose

Provee un contenedor base Alpine como esqueleto para almacenamiento de correos, con puertos expuestos, límites de recursos, y configuración por variables de entorno. No incluye software de mail específico — el usuario instala el servidor IMAP/POP3 que necesite.

## Requirements

### Requirement: Containerfile basado en Alpine
El sistema DEBE proveer un Containerfile basado en Alpine Linux con un entrypoint básico, sin instalar software de mail específico.

#### Scenario: Imagen se construye correctamente
- **WHEN** se ejecuta la build del Containerfile
- **THEN** se genera una imagen Alpine con el entrypoint copiado y permisos de ejecución

### Requirement: Puertos expuestos configurables
El sistema DEBE exponer puertos configurables mediante variables de entorno, sin hardcodear números de puerto en el compose.yaml.

#### Scenario: Puerto expuesto se configura vía variable de entorno
- **WHEN** se define `MAIL_STORAGE_PORT=143` en el `.env`
- **THEN** el contenedor expone el puerto 143 mapeado al host

### Requirement: Environment-driven configuration
Toda la configuración del servicio DEBE derivarse de variables de entorno, sin valores hardcodeados. El sistema DEBE proveer un archivo `.env.example` como plantilla documentada.

#### Scenario: Configuración vía env vars
- **WHEN** el contenedor inicia con las variables de entorno definidas en `.env`
- **THEN** el servicio toma los valores de las variables sin necesidad de editar archivos manualmente

### Requirement: Resource limits
El sistema DEBE imponer un límite de CPU de 0.5 cores y un límite de memoria de 512MB por defecto, configurables mediante variables de entorno.

#### Scenario: Container starts with default resource limits
- **WHEN** el contenedor se ejecuta sin modificar las variables de límite
- **THEN** el runtime aplica un límite de CPU de 0.5 y memoria de 512MB

### Requirement: Non-root execution
El sistema DEBE ejecutar el proceso como un usuario no-root y DEBE habilitar `no-new-privileges:true` en la definición del servicio.

#### Scenario: Container runs as non-root
- **WHEN** se inspecciona el proceso en ejecución
- **THEN** el proceso corre bajo un usuario sin privilegios de root

### Requirement: Persistent storage
El sistema DEBE montar un volumen en el host para que los datos sobrevivan a reinicios y recreaciones del contenedor.

#### Scenario: Container is recreated
- **WHEN** el contenedor se detiene, se elimina y se vuelve a crear usando el mismo volumen de datos
- **THEN** los datos previamente almacenados permanecen accesibles

### Requirement: SMTP server receives incoming mail
El sistema SHALL aceptar conexiones SMTP entrantes en el puerto 25 y almacenar los correos recibidos en el directorio de cola de Postfix.

#### Scenario: Client sends an email via SMTP
- **WHEN** un cliente externo se conecta al puerto 25 y envía un comando `MAIL FROM`, `RCPT TO` y `DATA` válidos
- **THEN** Postfix acepta el mensaje y lo encola para entrega local

### Requirement: SMTP server relays outgoing mail
El sistema SHALL permitir el envío de correos salientes a destinos externos a través de SMTP en el puerto 25.

#### Scenario: Outbound email is relayed
- **WHEN** un cliente autorizado envía un correo con destino a un dominio externo
- **THEN** Postfix intenta la entrega al servidor MX del dominio destino

### Requirement: No TLS enforcement
El sistema SHALL NOT requerir ni ofrecer TLS en las conexiones SMTP entrantes o salientes. Las conexiones se manejan en texto plano.

#### Scenario: Plaintext SMTP connection accepted
- **WHEN** un cliente se conecta al puerto 25 sin iniciar STARTTLS
- **THEN** Postfix procesa los comandos SMTP normalmente sin negociar cifrado

### Requirement: No IMAP or POP3 service
El sistema SHALL NOT incluir ni exponer servicios IMAP o POP3. Solo el servicio SMTP está disponible.

#### Scenario: IMAP port is not exposed
- **WHEN** se inspeccionan los puertos expuestos del contenedor
- **THEN** no hay ningún puerto IMAP (143) ni POP3 (110) en exposición

### Requirement: SMTP configuration via environment variables
La configuración SMTP de Postfix (hostname, dominio, redes permitidas) SHALL derivarse de variables de entorno definidas en `.env`. El `.env.example` SHALL documentar todas las variables SMTP nuevas.

#### Scenario: SMTP hostname configured via environment variable
- **WHEN** se define `SMTP_MYHOSTNAME=mail.example.com` en el `.env`
- **THEN** Postfix usa `mail.example.com` como su hostname en las cabeceras SMTP

#### Scenario: SMTP allowed networks configured via environment variable
- **WHEN** se define `SMTP_MYNETWORKS=192.168.1.0/24` en el `.env`
- **THEN** Postfix permite relay desde la red 192.168.1.0/24
