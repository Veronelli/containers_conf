## 1. Estructura del proyecto

- [ ] 1.1 Crear carpeta `mail-server/` con `.gitignore` que ignore `.env`, `data/` y `logs/`

## 2. Containerfile

- [ ] 2.1 Crear Containerfile basado en `alpine:latest` con Postfix, Dovecot y supervisord
- [ ] 2.2 Configurar usuario/grupo `vmail` sin privilegios para ejecutar servicios
- [ ] 2.3 Copiar templates de configuración y entrypoint script

## 3. Configuración de Postfix

- [ ] 3.1 Crear template `main.cf` configurando dominio vía `MAIL_DOMAIN`, entrega LMTP a Dovecot, y Maildir como formato de buzón
- [ ] 3.2 Crear template `master.cf` con servicio LMTP hacia Dovecot

## 4. Configuración de Dovecot

- [ ] 4.1 Crear template `dovecot.conf` con autenticación PAM, protocolo IMAP en puerto 143, y almacenamiento Maildir
- [ ] 4.2 Crear archivo PAM `dovecot` para autenticación contra usuarios del sistema

## 5. Entrypoint script

- [ ] 5.1 Crear `docker-entrypoint.sh` que lea `MAIL_USER` y `MAIL_PASS`, cree usuario del sistema con Maildir, genere configuraciones con `envsubst`, e inicie supervisord

## 6. Supervisor

- [ ] 6.1 Crear `supervisord.conf` que arranque Postfix y Dovecot como procesos supervisados

## 7. Orquestación y configuración de entorno

- [ ] 7.1 Crear `.env.example` con variables `MAIL_DOMAIN`, `MAIL_USER` y `MAIL_PASS` documentadas
- [ ] 7.2 Crear `compose.yaml` exponiendo puertos 25 y 143, con límites de CPU/memoria, `no-new-privileges: true`, y montando volumen para `data/`
- [ ] 7.3 Crear `run-compose.sh` que cargue `.env` y ejecute compose

## 8. Documentación

- [ ] 8.1 Crear `README.md` con propósito, requisitos, quick-start, tabla de variables de entorno y notas de seguridad

## 9. Verificación

- [ ] 9.1 Construir la imagen y levantar el contenedor, verificar que Postfix escucha en puerto 25 y Dovecot en 143
- [ ] 9.2 Enviar un correo de prueba por SMTP y leerlo por IMAP usando un cliente como `mutt` o `curl`
