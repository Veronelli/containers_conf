## Context

`mail-storage` ejecuta Postfix y Dovecot desde `docker-entrypoint.sh`, con configuración generada por `envsubst`. El contenedor ya usa una imagen Alpine, un único servicio Compose, límites de recursos y `no-new-privileges:true`. El cliente No-IP debe convivir con ambos servicios sin convertirse en un requisito de build dependiente de credenciales.

## Goals / Non-Goals

**Goals:**

- Empaquetar el tarball exacto `noip-duc_3.3.0.tar.gz` en la imagen.
- Arrancar el cliente con credenciales y hostname exclusivamente desde el entorno del servicio.
- Supervisar el proceso DDNS junto con Postfix y Dovecot, con limpieza coordinada al recibir señales.
- Evitar que secretos aparezcan en archivos generados, logs o capas de la imagen.
- Mantener el comportamiento SMTP, IMAP, volúmenes y límites existentes.

**Non-Goals:**

- No administrar registros DNS distintos de No-IP.
- No introducir TLS para SMTP/IMAP ni modificar autenticación de correo.
- No persistir credenciales No-IP en el volumen `/data`.
- No crear un segundo contenedor o composición separada para DDNS.

## Decisions

- **Instalación desde el tarball proporcionado:** la etapa de build descargará la URL fija y colocará el ejecutable en una ruta del sistema. Esto evita depender de un repositorio de paquetes que podría no contener la versión solicitada. Como alternativa, instalar desde un paquete de Alpine sería más simple, pero no garantiza la versión 3.3.0.
- **Configuración únicamente por entorno:** Compose pasará `NOIP_USERNAME`, `NOIP_PASSWORD`, `NOIP_HOSTNAME` y `NOIP_UPDATE_INTERVAL`; el entrypoint validará las variables antes de iniciar el cliente. Se evita un archivo de configuración persistente porque podría terminar en capas, volúmenes o backups. Un secret mount queda como evolución futura, no como requisito de esta propuesta.
- **Supervisión en el entrypoint existente:** se agregará el PID del proceso No-IP al mismo ciclo de señales y supervisión que ya controla Postfix y Dovecot. No se agrega un supervisor general porque aumenta dependencias y cambia innecesariamente el modelo de proceso actual.
- **Fallo DDNS degradado:** una pérdida temporal de conectividad se registrará y permitirá reintentos, sin detener los servicios de correo. Una terminación inesperada del cliente será observable y podrá afectar el health check según la política definida, evitando ocultar una pérdida permanente de actualización.
- **Salud y secretos:** el health check verificará la disponibilidad del proceso o su estado operativo sin imprimir valores de entorno sensibles. Los mensajes de error deberán excluir `NOIP_PASSWORD`.

## Risks / Trade-offs

- **[Riesgo]** La URL externa puede dejar de estar disponible o entregar un artefacto inesperado. → Usar descarga estricta (`curl -f`), comprobar que el ejecutable esperado exista y fallar la build si no se puede instalar.
- **[Riesgo]** Ejecutar tres procesos en un contenedor complica señales y códigos de salida. → Mantener PIDs explícitos, trap de limpieza y una política documentada para distinguir fallos DDNS temporales de fallos de Postfix/Dovecot.
- **[Riesgo]** Variables de entorno pueden ser visibles para procesos con acceso al contenedor. → No escribirlas a disco ni registrarlas; documentar que el runtime debe proteger el `.env` y considerar secrets nativos en una iteración posterior.
- **[Riesgo]** Un intervalo demasiado agresivo puede provocar límites o rate limiting de No-IP. → Definir un intervalo por defecto conservador y hacerlo configurable.

## Migration Plan

1. Añadir las variables No-IP al `.env` local a partir de `.env.example` y completar credenciales reales fuera del repositorio.
2. Reconstruir y levantar `mail-storage`; verificar logs de actualización y el estado del health check.
3. Confirmar que Postfix e IMAP siguen respondiendo y que el hostname resuelve a la IP pública esperada.
4. Para rollback, retirar las variables DDNS y volver a construir la imagen anterior; el tráfico SMTP/IMAP no requiere migración de datos.

## Open Questions

- Ninguna que cambie el contrato o el enfoque; el intervalo predeterminado y los detalles exactos de flags del binario se validarán contra la ayuda del artefacto durante la implementación.
