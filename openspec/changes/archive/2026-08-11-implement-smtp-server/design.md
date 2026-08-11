## Context

La composición `mail-storage/` ya existe como esqueleto Alpine con puertos expuestos, volúmenes y límites de recursos. Este cambio le agrega Postfix para que pase de ser un contenedor pasivo a un servidor SMTP funcional. Ver proposal.md para la motivación.

El puerto SMTP (25) es privilegiado (<1024), por lo que el proceso master de Postfix debe iniciar como root para bindearlo. Los procesos hijos de Postfix (smtpd, cleanup, qmgr, pickup, etc.) se ejecutan como `nobody` mediante `default_privs` en main.cf.

## Goals / Non-Goals

**Goals:**
- Postfix funcional que recibe y entrega correos SMTP en el puerto 25, dentro de la composición `mail-storage/`
- Configuración SMTP templatizada desde variables de entorno en el entrypoint
- Cola de correos persistente vía el volumen de datos ya existente

**Non-Goals:**
- No se implementa TLS/STARTTLS
- No se incluye servidor IMAP ni POP3
- No se configura autenticación SMTP (SASL)
- No se configura relay a un smarthost externo

## Decisions

### Decisión 1: Alpine + postfix package

**Elección**: Usar `postfix` desde los repositorios oficiales de Alpine (`apk add postfix`) en el Containerfile existente.

**Alternativa considerada**: Compilar Postfix desde fuente. Rechazada por complejidad innecesaria — el paquete de Alpine es mantenido, ligero y suficiente para esta etapa.

### Decisión 2: Entrypoint genera main.cf con envsubst

**Elección**: El entrypoint (`docker-entrypoint.sh`) se reescribe para generar un `main.cf` desde variables de entorno usando `envsubst`, y arrancar Postfix en foreground en lugar del `tail -f /dev/null` actual.

**Alternativa considerada**: Usar `postconf -e` para setear variables una por una. Rechazada por verbosidad — `envsubst` sobre un archivo template es más mantenible y declarativo.

### Decisión 3: Master como root, hijos como nobody

**Elección**: El proceso master de Postfix corre como root (necesario para bindear puerto 25). Los procesos hijos usan `default_privs = nobody`. El compose.yaml mantiene `no-new-privileges:true`.

**Alternativa considerada**: Usar `cap_add: NET_BIND_SERVICE` + usuario no-root + puerto alto con port mapping. Rechazada porque Postfix espera correr en puerto 25 y cambiar el puerto interno complica la configuración sin ganancia real de seguridad en un contenedor aislado.

### Decisión 4: Sin TLS

**Elección**: No se configura TLS — sin certificados, sin `smtpd_tls_security_level`, sin STARTTLS.

**Alternativa considerada**: Incluir TLS básico con certificados autofirmados. Rechazada — el alcance explícito es SMTP plano. TLS se agregará en un cambio futuro.

## Risks / Trade-offs

- **[Riesgo] Postfix necesita root para puerto 25** → Mitigación: solo el master corre como root; los procesos hijos (smtpd, qmgr, etc.) usan `default_privs = nobody`. El contenedor tiene `no-new-privileges:true`.
- **[Riesgo] Sin TLS, el tráfico viaja en texto plano** → Mitigación: es una decisión explícita de diseño para esta fase. TLS se agregará en un cambio posterior.
- **[Riesgo] Sin autenticación, cualquiera en las redes permitidas puede relay** → Mitigación: `SMTP_MYNETWORKS` controla qué redes pueden relay. Por defecto solo localhost.

## Migration Plan

1. Modificar `Containerfile` para instalar `postfix` y crear los directorios de spool
2. Reescribir `docker-entrypoint.sh` para templatizar `main.cf` y arrancar Postfix
3. Agregar puerto 25 a `compose.yaml`
4. Agregar variables SMTP a `.env.example`
5. Actualizar `.gitignore` para excluir `data/`
6. Actualizar `README.md`

Rollback: revertir los archivos modificados a su estado anterior. La imagen y los volúmenes existentes no se ven afectados irreversiblemente.
