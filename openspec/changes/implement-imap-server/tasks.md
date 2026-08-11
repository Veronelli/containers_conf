## 1. Container image

- [ ] 1.1 Agregar Dovecot y el módulo de autenticación PAM requerido a los paquetes instalados por `mail-storage/Containerfile`
- [ ] 1.2 Crear los templates de configuración de Dovecot para IMAP en el puerto 143, PAM, buzón local y TLS deshabilitado
- [ ] 1.3 Preparar permisos y directorios runtime para que Dovecot pueda acceder a los buzones de los usuarios PAM sin alterar el volumen existente

## 2. Service configuration

- [ ] 2.1 Modificar `mail-storage/compose.yaml` para publicar el puerto IMAP interno 143 con host y puerto configurables por variables de entorno
- [ ] 2.2 Agregar a `mail-storage/.env.example` las variables de binding IMAP, hostname, ubicación del buzón, servicio PAM y política TLS deshabilitada
- [ ] 2.3 Verificar que el compose mantiene el puerto SMTP 25, los límites de CPU/memoria y `no-new-privileges:true`

## 3. Entrypoint and process lifecycle

- [ ] 3.1 Actualizar `mail-storage/docker-entrypoint.sh` para renderizar los templates de Dovecot con `envsubst` y validar la configuración antes de iniciar servicios
- [ ] 3.2 Iniciar Dovecot y Postfix en foreground desde el mismo entrypoint, propagando señales y deteniendo el contenedor si uno de los procesos termina
- [ ] 3.3 Confirmar mediante la configuración efectiva de Postfix la ruta/formato del buzón y ajustar el valor por defecto de `MAIL_STORAGE_MAIL_LOCATION` si fuera necesario

## 4. Documentation

- [ ] 4.1 Actualizar `mail-storage/README.md` con la arquitectura conjunta Postfix+Dovecot, puertos, variables y requisitos de usuarios PAM
- [ ] 4.2 Documentar explícitamente que IMAP y SMTP operan sin TLS y que la persistencia de buzones queda fuera de esta fase

## 5. Verification

- [ ] 5.1 Construir la imagen y verificar que Dovecot acepta su configuración generada sin errores
- [ ] 5.2 Levantar la composición y comprobar que los puertos 25 y 143 están escuchando, mientras el puerto POP3 110 permanece cerrado
- [ ] 5.3 Probar autenticación IMAP con credenciales PAM válidas y confirmar que credenciales inválidas son rechazadas
- [ ] 5.4 Crear como fixtures temporales los usuarios PAM `test-sender` y `test-reader`, inyectando credenciales solo durante el health check
- [ ] 5.5 Enviar desde `test-sender@mail.example.com` un mensaje con asunto `test` a `test-reader@mail.example.com` y verificar por IMAP que `test-reader` puede autenticarse y leerlo en INBOX
- [ ] 5.6 Registrar la limpieza antes de crear los fixtures y eliminar siempre `test-sender`, `test-reader`, sus credenciales y los datos de prueba, incluso ante fallos
