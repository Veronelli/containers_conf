## MODIFIED Requirements

### Requirement: Containerfile basado en Alpine
El sistema SHALL proveer un Containerfile basado en Alpine Linux con un entrypoint ejecutable e incluir los servicios de mail y el cliente DDNS requeridos por las capacidades declaradas. Las dependencias externas MUST instalarse durante la construcción y sus versiones relevantes MUST quedar reproducibles.

#### Scenario: Imagen se construye correctamente
- **WHEN** se ejecuta la build del Containerfile
- **THEN** se genera una imagen Alpine con Postfix, Dovecot, el cliente No-IP y el entrypoint copiados o instalados con permisos de ejecución

### Requirement: Environment-driven configuration
Toda la configuración del servicio SHALL derivarse de variables de entorno, sin valores hardcodeados. El sistema MUST proveer un archivo `.env.example` como plantilla documentada, incluyendo las variables de usuario, contraseña y hostname requeridas por No-IP.

#### Scenario: Configuración vía env vars
- **WHEN** el contenedor inicia con las variables de entorno definidas en `.env`
- **THEN** Postfix, Dovecot y el cliente DDNS toman sus valores sin necesidad de editar archivos manualmente

#### Scenario: Secret is not persisted in the image
- **WHEN** se inspeccionan el Containerfile, los artefactos versionados y la imagen construida
- **THEN** la contraseña No-IP no aparece escrita en ninguno de ellos y solo se entrega en tiempo de ejecución
