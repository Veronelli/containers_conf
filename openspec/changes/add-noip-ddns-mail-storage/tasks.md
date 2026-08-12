## 1. Empaquetado del cliente No-IP

- [x] 1.1 Descargar el tarball `noip-duc_3.3.0.tar.gz` desde la URL proporcionada durante el build y validar que el ejecutable esperado esté presente.
- [x] 1.2 Instalar el binario en la imagen Alpine de `mail-storage` con permisos de ejecución y sin incluir credenciales en ninguna capa.
- [x] 1.3 Verificar mediante una build limpia que Postfix, Dovecot y `noip-duc` estén disponibles en la imagen final.

## 2. Configuración y ejecución DDNS

- [x] 2.1 Añadir `NOIP_USERNAME`, `NOIP_PASSWORD`, `NOIP_HOSTNAME` y `NOIP_UPDATE_INTERVAL` al `compose.yaml` y `.env.example`, con valores por defecto seguros y sin secretos reales.
- [x] 2.2 Confirmar los flags y el modo de ejecución periódica soportados por `noip-duc` 3.3.0, y encapsularlos en la configuración del entrypoint.
- [x] 2.3 Validar las variables obligatorias antes de iniciar el cliente y producir mensajes accionables que nunca impriman `NOIP_PASSWORD`.
- [x] 2.4 Iniciar `noip-duc` junto con Postfix y Dovecot desde `docker-entrypoint.sh`, supervisar sus PIDs y detenerlo correctamente mediante el trap existente.
- [x] 2.5 Implementar reintento periódico ante fallos temporales y una política observable para terminación inesperada del cliente sin detener automáticamente los servicios de correo.

## 3. Salud, documentación y verificación

- [x] 3.1 Extender el health check para detectar el estado DDNS sin exponer credenciales y conservar las verificaciones SMTP/IMAP existentes.
- [x] 3.2 Documentar en `README.md` el flujo DDNS, conectividad saliente requerida, variables, protección del `.env` y comportamiento ante fallos.
- [ ] 3.3 Levantar la composición con credenciales de prueba o entorno controlado, comprobar una actualización exitosa del hostname y confirmar que los logs no contienen la contraseña.
- [ ] 3.4 Verificar regresión de SMTP e IMAP, límites de recursos, `no-new-privileges:true`, reinicio del servicio y resolución del hostname No-IP.
