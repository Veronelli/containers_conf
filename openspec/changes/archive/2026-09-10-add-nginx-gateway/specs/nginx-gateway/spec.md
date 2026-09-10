## Purpose

Proporciona un punto de entrada Nginx configurable que publica servicios internos por dominio y aplica controles de acceso definidos por el operador.

## ADDED Requirements

### Requirement: Composición de gateway segura y agnóstica al runtime
El sistema SHALL proporcionar una composición independiente de Nginx con `Containerfile`, `compose.yaml`, `.env.example`, `.gitignore`, script de inicio, script de ejecución y README. El proceso SHALL ejecutarse sin privilegios de root, la definición de servicio SHALL habilitar `no-new-privileges:true`, y los límites de CPU y memoria SHALL configurarse mediante variables de entorno.

#### Scenario: Gateway iniciado con configuración de ejemplo
- **WHEN** el operador crea `.env` a partir de `.env.example` y ejecuta el script de composición
- **THEN** el gateway inicia con sus puertos, límites de recursos y nombre de red definidos por variables de entorno sin requerir un runtime específico en los archivos versionados

### Requirement: Enrutamiento por dominio a servicios internos
El sistema SHALL aceptar una lista configurable de rutas que asocie cada dominio con un servicio y puerto de destino accesibles en una red externa compartida. El gateway SHALL reenviar a dicho destino las solicitudes cuyo encabezado `Host` coincida con el dominio configurado, preservando la información de host, esquema y dirección del cliente mediante encabezados de proxy.

#### Scenario: Solicitud dirigida a un dominio configurado
- **WHEN** una solicitud HTTP llega al gateway con un encabezado `Host` que coincide con una ruta configurada
- **THEN** el gateway reenvía la solicitud al servicio y puerto de destino asociados a ese dominio

#### Scenario: Dominio no configurado
- **WHEN** una solicitud HTTP llega con un encabezado `Host` que no corresponde a ninguna ruta configurada
- **THEN** el gateway no la reenvía a un servicio interno y responde con un error HTTP de cliente

### Requirement: Reglas de acceso por ruta
El sistema SHALL permitir que cada ruta configure una política de acceso independiente: acceso público, restricción por redes IP permitidas o autenticación básica HTTP. Las credenciales de autenticación básica SHALL obtenerse de variables de entorno y SHALL NOT incluirse en archivos versionados.

#### Scenario: Cliente desde una red permitida
- **WHEN** una ruta configurada con restricción IP recibe una solicitud desde una dirección perteneciente a su lista permitida
- **THEN** el gateway permite la solicitud y la reenvía al destino de la ruta

#### Scenario: Cliente no autorizado por IP
- **WHEN** una ruta configurada con restricción IP recibe una solicitud desde una dirección no incluida en su lista permitida
- **THEN** el gateway responde con HTTP 403 y no reenvía la solicitud al servicio interno

#### Scenario: Autenticación básica válida
- **WHEN** una ruta configurada con autenticación básica recibe credenciales válidas
- **THEN** el gateway permite la solicitud y la reenvía al destino de la ruta

### Requirement: Configuración y diagnóstico operables
El sistema SHALL validar la configuración generada antes de iniciar Nginx y SHALL finalizar con un error descriptivo si una ruta o política de acceso es inválida. El README SHALL documentar el formato de rutas, las políticas de acceso, las variables de entorno, la conexión a la red compartida y el procedimiento para agregar un nuevo servicio.

#### Scenario: Configuración de ruta inválida
- **WHEN** el operador proporciona una ruta sin dominio, destino o política de acceso válida
- **THEN** el contenedor no inicia Nginx y emite un mensaje que identifica la configuración inválida
