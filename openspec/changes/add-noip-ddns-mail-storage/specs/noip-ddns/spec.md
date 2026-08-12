## Purpose

Proporciona actualización automática y segura de un hostname No-IP desde el contenedor `mail-storage`, manteniendo el registro alineado con la IP pública actual del host.

## ADDED Requirements

### Requirement: No-IP client is included in mail-storage
La imagen de `mail-storage` SHALL incluir el cliente `noip-duc` versión `3.3.0`, obtenido desde `https://dmej8g5cpdyqd.cloudfront.net/downloads/noip-duc_3.3.0.tar.gz` durante la construcción de la imagen.

#### Scenario: Image contains the requested client
- **WHEN** se construye la imagen de `mail-storage`
- **THEN** el binario ejecutable de `noip-duc` versión 3.3.0 está disponible dentro del contenedor

### Requirement: DDNS credentials and hostname are runtime configuration
El cliente SHALL recibir el usuario No-IP mediante `NOIP_USERNAME`, la contraseña mediante `NOIP_PASSWORD` y el hostname DDNS mediante `NOIP_HOSTNAME`. Ninguno de estos valores SHALL estar hardcodeado en la imagen o en archivos versionados.

#### Scenario: Client starts with supplied environment
- **WHEN** el contenedor inicia con `NOIP_USERNAME`, `NOIP_PASSWORD` y `NOIP_HOSTNAME` definidos
- **THEN** el cliente usa esos valores para actualizar el hostname indicado

#### Scenario: Required configuration is missing
- **WHEN** falta cualquiera de las variables obligatorias de No-IP
- **THEN** el cliente no inicia una actualización autenticada y el contenedor registra un error accionable sin imprimir la contraseña

### Requirement: DDNS updates run periodically
El cliente SHALL intentar actualizar el hostname configurado de forma periódica mientras el contenedor esté activo, usando un intervalo configurable por `NOIP_UPDATE_INTERVAL`.

#### Scenario: Periodic update succeeds
- **WHEN** No-IP responde satisfactoriamente a una actualización
- **THEN** el cliente registra un resultado exitoso sin exponer credenciales y vuelve a intentar en el siguiente intervalo

#### Scenario: No-IP is temporarily unavailable
- **WHEN** la red o el servicio No-IP no está disponible durante una actualización
- **THEN** el cliente registra el fallo, mantiene activos los servicios de correo y reintenta periódicamente

### Requirement: DDNS process failure is observable
El estado del cliente DDNS SHALL ser observable en los logs del contenedor y su fallo permanente SHALL poder reflejarse en el mecanismo de health check sin impedir que Postfix y Dovecot continúen prestando servicio mientras el proceso auxiliar se recupera.

#### Scenario: DDNS process exits unexpectedly
- **WHEN** el proceso del cliente termina inesperadamente
- **THEN** el contenedor registra la terminación y ejecuta la política definida de reinicio o marca el health check como no saludable
