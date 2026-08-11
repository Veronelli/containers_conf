## MODIFIED Requirements

### Requirement: No IMAP or POP3 service
El sistema SHALL incluir un servicio IMAP en el puerto 143 y SHALL NOT incluir ni exponer servicios POP3. El servicio IMAP debe ejecutarse dentro del contenedor `mail-storage` existente junto con SMTP.

#### Scenario: IMAP port is exposed
- **WHEN** se inspeccionan los puertos publicados del servicio `mail-storage`
- **THEN** existe un binding configurable hacia el puerto interno 143 y el puerto SMTP 25 continúa disponible

#### Scenario: POP3 remains unavailable
- **WHEN** un cliente intenta conectarse al puerto POP3 110
- **THEN** el servicio no ofrece un listener POP3

## ADDED Requirements

### Requirement: IMAP provides local mailbox access
El sistema SHALL permitir que un cliente autenticado consulte, liste, lea y gestione los mensajes del buzón local entregado por Postfix mediante IMAP.

#### Scenario: Authenticated user reads mailbox
- **WHEN** un usuario se autentica correctamente y selecciona su buzón INBOX mediante IMAP
- **THEN** puede listar y leer los mensajes que Postfix entregó a su buzón local

### Requirement: IMAP authentication uses PAM
El sistema SHALL validar las credenciales IMAP mediante PAM y SHALL rechazar credenciales inválidas sin conceder acceso al buzón.

#### Scenario: Valid PAM credentials are accepted
- **WHEN** un usuario existente en la base de autenticación PAM presenta credenciales válidas por IMAP
- **THEN** el servidor permite la sesión IMAP y la asocia con el buzón local de ese usuario

#### Scenario: Invalid credentials are rejected
- **WHEN** un cliente presenta una contraseña inválida por IMAP
- **THEN** el servidor rechaza la autenticación y no permite consultar ningún buzón

### Requirement: IMAP configuration is environment-driven
La configuración operativa de IMAP SHALL derivarse de variables de entorno documentadas en `.env.example`, incluyendo el binding del puerto, el hostname del servicio y la ubicación del buzón. El arranque no debe requerir editar manualmente archivos generados dentro de la imagen.

#### Scenario: IMAP binding is configured through environment
- **WHEN** se define un host y puerto de binding IMAP en `.env`
- **THEN** el servicio publica el puerto interno 143 usando esos valores

#### Scenario: IMAP mailbox location is configured through environment
- **WHEN** se define la ubicación del buzón IMAP en `.env`
- **THEN** Dovecot usa esa ubicación para resolver el buzón del usuario autenticado

### Requirement: IMAP operates without TLS
El sistema SHALL aceptar conexiones IMAP sin TLS y SHALL NOT habilitar TLS ni STARTTLS en esta fase.

#### Scenario: Plaintext IMAP connection is accepted
- **WHEN** un cliente se conecta al puerto 143 y negocia IMAP sin iniciar TLS
- **THEN** el servidor permite continuar con la autenticación PAM y la sesión IMAP

#### Scenario: TLS is not advertised
- **WHEN** un cliente solicita capacidades del servidor IMAP
- **THEN** la respuesta no anuncia STARTTLS ni requiere certificados para completar la conexión

### Requirement: Existing SMTP behavior remains available
La incorporación de IMAP SHALL preservar la capacidad existente de Postfix para recibir y entregar correo SMTP en el puerto 25, sin cambiar sus restricciones de relay configuradas.

#### Scenario: SMTP remains reachable after IMAP startup
- **WHEN** el contenedor inicia con IMAP habilitado
- **THEN** Postfix escucha en el puerto 25 y acepta las conexiones SMTP permitidas por su configuración actual

### Requirement: End-to-end mail flow is verifiable
El sistema SHALL permitir validar el flujo completo mediante dos usuarios PAM temporales: `test-sender` envía un mensaje con asunto `test` a `test-reader@mail.example.com`, y `test-reader` lo autentica y lee por IMAP. La validación SHALL eliminar ambos usuarios fixture y sus datos de prueba al finalizar, incluso cuando una aserción falle.

#### Scenario: Fixture users send and read a test message
- **WHEN** el health check crea `test-sender` y `test-reader`, envía un mensaje desde `test-sender@mail.example.com` a `test-reader@mail.example.com` con asunto `test`, y `test-reader` inicia sesión por IMAP
- **THEN** la bandeja INBOX de `test-reader` contiene un mensaje con asunto `test` y remitente `test-sender@mail.example.com`

#### Scenario: Fixture cleanup runs after the health check
- **WHEN** el health check termina correctamente o con error
- **THEN** elimina las cuentas PAM temporales `test-sender` y `test-reader`, sus credenciales y los datos de correo creados exclusivamente para la prueba
