# GeffenWeverse

GeffenWeverse es una plataforma de comunidad y fans dentro del ecosistema Starship Legacy.

## Fuente oficial de la interfaz

La versión de referencia aprobada es:

- **Actual:** [`geffenweverse-web-2026-11-14.html`](./geffenweverse-web-2026-11-14.html)
- **Respaldo anterior:** [`geffenweverse-web.html`](./geffenweverse-web.html) — conservar; no usar como base para nuevas integraciones.

La interfaz actual es una aplicación HTML/CSS/JavaScript de archivo único. Mantener su diseño y comportamiento visual mientras se conecta progresivamente con el backend.

## Estructura del repositorio

```
.
├── geffenweverse-web-2026-11-14.html  # interfaz oficial de referencia
├── geffenweverse-web.html             # versión anterior conservada
├── README.md
├── docs/
│   └── INTEGRATION_MATRIX.md           # estado por pantalla y plan de integración
└── supabase/
    └── migrations/                     # SQL versionado
```

## Estado actual

- El HTML oficial está versionado en GitHub.
- La interfaz todavía contiene datos de ejemplo y acciones simuladas.
- Supabase contiene el esquema principal y políticas RLS; la interfaz aún no está conectada a un cliente Supabase.
- No hay Edge Functions desplegadas en el proyecto consultado.
- No se ha establecido todavía un proveedor de hosting ni una configuración de despliegue dentro de este repositorio.

Consulta la [matriz de integración](./docs/INTEGRATION_MATRIX.md) para ver cada pantalla, sus tablas, operaciones y pendientes.

## Supabase y seguridad

- Mantener RLS habilitado en las tablas expuestas.
- Usar solo una clave publishable en el frontend.
- No guardar `service_role`, claves secretas de pago, contraseñas ni tokens privados en GitHub o en el HTML.
- Mantener `digital_codes` sin acceso desde el cliente; el canje debe validarse del lado servidor.
- Los pagos deben verificarse del lado servidor antes de cambiar el estado de un pedido.
- No volver a ejecutar migraciones existentes sin reconciliar primero los archivos SQL con el historial real del proyecto.

## Desarrollo y despliegue

El HTML puede abrirse directamente en un navegador para una revisión visual. Para producción, primero se debe definir el proveedor de hosting, la ruta de entrada y la configuración pública de Supabase. No se debe publicar como “integrado” hasta probar autenticación, políticas, almacenamiento y flujos de datos reales.

## Historial y cambios

Mantener la versión anterior como respaldo. Los cambios de integración deben documentarse y realizarse en commits pequeños, verificables y reversibles.
