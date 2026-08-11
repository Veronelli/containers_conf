## 1. Container image

- [x] 1.1 Modificar `Containerfile` para instalar `postfix` vía `apk add` y crear los directorios de spool (`/var/spool/postfix`) con permisos adecuados

## 2. Entrypoint

- [x] 2.1 Reescribir `docker-entrypoint.sh` para generar `main.cf` desde variables de entorno con `envsubst` y arrancar `postfix start-fg`

## 3. Service definition

- [x] 3.1 Modificar `compose.yaml` para exponer el puerto 25 con binding configurable por variable de entorno

## 4. Configuration template

- [x] 4.1 Agregar variables SMTP a `.env.example` (SMTP_MYHOSTNAME, SMTP_MYNETWORKS, SMTP_MYDOMAIN, SMTP_MYDESTINATION, SMTP_BIND_HOST, SMTP_BIND_PORT)

## 5. Gitignore

- [x] 5.1 Agregar `data/` a `.gitignore`

## 6. Documentation

- [x] 6.1 Actualizar `README.md` documentando Postfix, variables SMTP y quick-start

## 7. Verification

- [x] 7.1 Construir la imagen y verificar que el contenedor arranca sin errores
- [x] 7.2 Verificar que el puerto 25 está accesible y acepta conexiones SMTP
