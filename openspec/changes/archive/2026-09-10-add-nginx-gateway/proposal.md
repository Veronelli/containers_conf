## Why

Las composiciones actuales exponen sus servicios de forma independiente, lo que dificulta centralizar el acceso cuando se incorporan nuevos servicios. Se necesita un punto de entrada Nginx configurable que dirija el tráfico por dominio y permita definir controles de acceso de forma consistente.

## What Changes

- Añadir una composición Nginx independiente que actúe como proxy inverso y punto de entrada HTTP/HTTPS para servicios de la plataforma.
- Permitir declarar rutas virtuales por dominio y servicio de destino mediante configuración versionable y variables de entorno.
- Incluir mecanismos configurables para aplicar reglas de acceso por ruta o dominio.
- Proporcionar scripts, plantilla de entorno y documentación siguiendo las convenciones de composiciones del repositorio.

## Capabilities

### New Capabilities
- `nginx-gateway`: Proporciona un proxy inverso Nginx configurable para publicar servicios mediante dominios y aplicar reglas de acceso.

### Modified Capabilities

- Ninguna.

## Impact

- Añade una nueva composición raíz para Nginx, su imagen OCI, definición de servicio, configuración de arranque y documentación.
- Los servicios que se publiquen detrás del gateway deberán compartir una red accesible con él y aportar su configuración de ruta.
- Incorpora la imagen oficial de Nginx como dependencia de tiempo de ejecución.
