## Context

El repositorio agrupa composiciones de contenedores autocontenidas y exige configuración mediante variables de entorno, ejecución sin root, límites explícitos de recursos y nomenclatura agnóstica al runtime. No existe actualmente un proxy de entrada compartido. La motivación y el alcance funcional se describen en `proposal.md`; los requisitos se definen en `specs/nginx-gateway/spec.md`.

## Goals / Non-Goals

**Goals:**
- Publicar varios servicios conectados a una misma red externa mediante un único puerto de entrada y enrutamiento por nombre de host.
- Generar configuración Nginx reproducible desde un `.env` no versionado.
- Aplicar políticas de acceso por host sin modificar las composiciones de los servicios destino.
- Hacer que los errores de configuración sean detectables antes de servir tráfico.

**Non-Goals:**
- Descubrir servicios automáticamente ni administrar su ciclo de vida.
- Proveer emisión o renovación automática de certificados TLS en esta primera composición.
- Sustituir un proveedor de identidad, WAF o gestión centralizada de secretos.
- Publicar rutas por prefijo de URL; inicialmente cada destino se resuelve por dominio completo.

## Decisions

### Generar virtual hosts a partir de una variable estructurada

El archivo `.env` declarará una lista multilínea `NGINX_ROUTES`, con una entrada por host en formato delimitado que incluya dominio, destino `servicio:puerto` y política de acceso. El entrypoint validará y transformará esas entradas en archivos de servidor Nginx antes de ejecutar la comprobación de sintaxis.

Esta elección conserva toda la configuración operativa en variables de entorno y permite añadir destinos sin editar archivos de configuración versionados. Se descarta mantener virtual hosts manuales bajo control de versiones porque incumpliría la configuración por entorno; también se descarta una API de administración porque añade persistencia, autenticación y superficie de ataque innecesarias.

### Usar una red externa configurable como integración explícita

La composición conectará el gateway a una red externa cuyo nombre se obtiene de `NGINX_NETWORK_NAME`. Cada servicio publicado debe adjuntarse a esa red y usar un nombre de servicio resoluble desde ella.

Esto evita acoplar el gateway a una composición concreta y funciona con diferentes runtimes compatibles con Compose. Se descarta conectar automáticamente redes de otros proyectos, pues las redes son recursos del runtime y no se pueden descubrir de forma portable.

### Políticas de acceso limitadas a mecanismos nativos de Nginx

Cada ruta admitirá `public`, `allowlist` y `basic-auth`. Las listas IP se declararán en variables de entorno asociadas a la ruta y las credenciales se entregarán como variables de entorno para generar un archivo de contraseñas de permisos restringidos durante el inicio.

Nginx ofrece estos controles sin incorporar servicios adicionales. Se descartan OAuth/OIDC y reglas WAF en esta fase porque requieren proveedores externos, definición de flujos de autenticación y mantenimiento adicional.

### Contenedor endurecido con configuración temporal escribible

La imagen añadirá las herramientas mínimas necesarias para generar y verificar la configuración, preparará directorios de trabajo propiedad del usuario no privilegiado y ejecutará Nginx con esa identidad. La configuración generada y las credenciales se crearán en almacenamiento temporal del contenedor, no en la imagen ni en el repositorio.

Esto permite templado sin secretos persistentes y mantiene el proceso sin root. Se descarta generar archivos durante la build, ya que los valores y secretos pertenecen al entorno de ejecución.

## Risks / Trade-offs

- [Un delimitador en `NGINX_ROUTES` puede resultar incómodo para valores complejos] → Se documentará un formato acotado, se validarán los campos y se rechazará cualquier entrada ambigua.
- [Las listas IP dependen de que la dirección del cliente llegue correctamente] → Se documentará que, detrás de otro proxy o balanceador, el operador debe configurar una red de confianza y los encabezados de cliente antes de basarse en allowlists.
- [La autenticación básica expone credenciales al entorno del proceso] → Se restringirán los permisos del archivo generado y se documentará el uso de un mecanismo de secretos del runtime para inyectar las variables.
- [No hay TLS automatizado] → La composición servirá inicialmente como punto de entrada HTTP y podrá ubicarse detrás de un terminador TLS; la incorporación de certificados será un cambio posterior explícito.

## Migration Plan

1. Crear la red externa compartida una vez mediante el runtime elegido.
2. Conectar a esa red cada servicio que se vaya a publicar, conservando sus puertos actuales durante la transición.
3. Configurar una ruta del gateway para cada dominio y validar su inicio.
4. Cambiar DNS o el balanceador frontal para dirigir cada dominio al gateway y comprobar el servicio publicado.
5. Retirar las exposiciones directas al host únicamente después de verificar rutas, políticas y observabilidad.

Para revertir, se restaura el DNS o balanceador a la exposición directa anterior y se detiene el gateway; los servicios de destino no requieren cambios destructivos.
