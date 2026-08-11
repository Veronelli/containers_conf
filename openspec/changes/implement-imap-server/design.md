## Context

`mail-storage/` es una composición Alpine que ya ejecuta Postfix en el puerto 25 y genera `main.cf` desde variables de entorno. El cambio debe añadir acceso IMAP al mismo contenedor, sin crear una composición separada ni alterar el contrato SMTP. La especificación delta define el comportamiento observable; este documento fija la integración interna.

## Goals / Non-Goals

**Goals:**

- Instalar y configurar Dovecot para IMAP plano en el puerto interno 143.
- Usar PAM del sistema para validar usuarios y asociar cada sesión con su buzón local.
- Permitir que Dovecot lea el formato de buzón que Postfix ya entrega.
- Arrancar Postfix y Dovecot desde un único entrypoint con señales y salida de procesos gestionadas.
- Mantener configuración sensible y específica del entorno fuera de la imagen, con valores de ejemplo documentados.
- Probar el flujo SMTP → buzón local → IMAP con fixtures PAM temporales y limpieza garantizada.

**Non-Goals:**

- TLS, STARTTLS, certificados o autenticación segura sobre transporte cifrado.
- POP3, SMTP AUTH, gestión de usuarios PAM o una API de administración de cuentas.
- Añadir, quitar o rediseñar volúmenes y persistencia de buzones.
- Crear un segundo contenedor o cambiar el servicio SMTP existente.

## Decisions

### Decisión 1: Dovecot dentro del contenedor `mail-storage`

**Elección**: Instalar el paquete Dovecot de Alpine en el `Containerfile` existente y ejecutar ambos demonios en el mismo servicio.

**Alternativa considerada**: Crear un servicio IMAP separado. Se rechaza porque el usuario necesita reutilizar el contenedor que ya recibe y envía correo, y un servicio separado complicaría el acceso al buzón local sin aportar valor en esta fase.

### Decisión 2: PAM como backend de autenticación

**Elección**: Configurar Dovecot para usar el mecanismo PAM del sistema y documentar el nombre del servicio PAM mediante variable de entorno. El usuario IMAP se resuelve como usuario local, por lo que sus permisos también controlan el acceso al buzón.

**Alternativa considerada**: `passwd-file` administrado por variables de entorno. Se rechaza porque duplicaría credenciales y no cumpliría la validación PAM solicitada.

### Decisión 3: Buzón local compatible con Postfix

**Elección**: Configurar la ubicación de correo de Dovecot mediante variable de entorno, con un valor de ejemplo para buzones mbox locales en `/var/mail/%u`, y mantener el formato alineado con la entrega local de Postfix.

**Alternativa considerada**: Maildir nuevo bajo `/data`. Se rechaza porque introduciría una decisión de persistencia y migración que el usuario dejó para una etapa posterior.

### Decisión 4: Configuración generada en el arranque

**Elección**: Añadir templates de Dovecot y expandirlos con `envsubst` desde el entrypoint, igual que la configuración SMTP. Las variables de entorno controlan puerto, hostname, ubicación del buzón, servicio PAM y política TLS.

**Alternativa considerada**: Editar los archivos de Dovecot durante la construcción de la imagen. Se rechaza porque impediría adaptar el contenedor a cada entorno sin reconstruirlo.

### Decisión 5: Supervisión de dos procesos

**Elección**: El entrypoint iniciará Dovecot en foreground y Postfix en foreground como procesos hijos, propagará SIGTERM/SIGINT a ambos y devolverá un estado no exitoso si alguno termina inesperadamente.

**Alternativa considerada**: Ejecutar un demonio en background sin supervisión. Se rechaza porque el contenedor podría permanecer healthy mientras IMAP o SMTP estuviera caído.

### Decisión 6: Health check con dos usuarios fixture

**Elección**: El health check creará temporalmente los usuarios PAM `test-sender` y `test-reader`. Enviará un mensaje desde `test-sender@mail.example.com` hacia `test-reader@mail.example.com`, con asunto `test`, abrirá la INBOX de `test-reader` por IMAP y verificará remitente y asunto. Las credenciales se inyectarán únicamente durante la prueba y una rutina de limpieza con `trap` eliminará ambos usuarios y sus datos aun si una aserción falla.

**Alternativa considerada**: Probar solo el listener IMAP o reutilizar cuentas permanentes. Se rechaza porque no valida la integración completa con Postfix y puede contaminar o exponer datos de desarrollo.

## Risks / Trade-offs

- **[Riesgo] IMAP plano expone credenciales y mensajes** → Mitigación: mantener TLS explícitamente fuera del alcance, documentarlo como advertencia y limitar el uso a redes controladas hasta implementar cifrado.
- **[Riesgo] PAM depende de usuarios y módulos disponibles en Alpine** → Mitigación: instalar el módulo PAM requerido, validar la configuración con `dovecot -n` y probar autenticación con un usuario local de prueba.
- **[Riesgo] Dos demonios en un contenedor complican señales y observabilidad** → Mitigación: ejecutar ambos en foreground, enviar logs a stdout/stderr cuando sea posible y hacer que la salida de cualquiera detenga el contenedor.
- **[Riesgo] Los buzones no son persistentes en esta fase** → Mitigación: no prometer durabilidad en la documentación; reservar el diseño de volúmenes para un cambio posterior.
- **[Riesgo] El formato de entrega de Postfix puede no coincidir con el valor elegido para Dovecot** → Mitigación: verificar en la imagen construida dónde entrega Postfix, parametrizar `MAIL_STORAGE_MAIL_LOCATION` y cubrir lectura de un mensaje end-to-end.
- **[Riesgo] Un health check fallido deja cuentas o correo de prueba** → Mitigación: registrar la limpieza antes de crear los fixtures y ejecutar siempre la rutina de eliminación mediante `trap`.

## Migration Plan

1. Añadir Dovecot y sus templates de configuración a la imagen `mail-storage`.
2. Agregar variables IMAP al `.env.example` y el binding configurable del puerto 143 al compose.
3. Actualizar el entrypoint para generar la configuración, validar Dovecot y supervisar ambos procesos.
4. Construir la imagen y comprobar que SMTP e IMAP quedan escuchando simultáneamente.
5. Crear temporalmente `test-sender` y `test-reader`, enviar el mensaje de prueba a `test-reader@mail.example.com`, leerlo por IMAP y eliminar los fixtures incluso si la prueba falla.

Rollback: volver a la imagen y configuración anteriores elimina el listener IMAP y conserva el servicio SMTP. No se requiere migración de datos porque este cambio no modifica volúmenes ni formato de buzón de forma intencional.
