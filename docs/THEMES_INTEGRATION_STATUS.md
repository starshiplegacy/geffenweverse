# Estado de integración: temas y pedidos

Última revisión: 2026-11-15.

## Estado seguro actual

- `index.html` carga la interfaz oficial y añade `gw-extensions.js` después del script principal.
- La extensión presenta un catálogo informativo; **no habilita compras, checkout ni aceptación de pagos**.
- La lista de temas adquiridos se deriva de pedidos leídos para la sesión actual. La interfaz nunca debe cambiar un pedido a pagado.
- El SQL `20261115120000_temas_catalogo.sql` sigue pendiente de reconciliación con el historial real de Supabase. No ejecutarlo ni duplicarlo hasta confirmar el flujo oficial de migraciones.
- No se ha verificado el despliegue web en un proveedor de hosting desde este repositorio.

## Dependencias del HTML oficial

La extensión espera que `geffenweverse-web-2026-11-14.html` cargue primero y defina `productos`, `pedidos`, `currentUser`, `supabaseClient`, `pages`, `J`, `I`, `esc`, `usd`, `toast`, `render`, `tiendaTop`, `herramientas`, `barra`, `vacio` y `upBtn`. Si cambia el HTML de referencia, volver a validar este contrato antes de publicar.

## Pruebas manuales antes de publicar

1. Servir el repositorio por HTTP(S) y comprobar que la interfaz oficial y `gw-extensions.js` cargan sin errores en consola.
2. Probar ruta inicial, `#tienda-temas`, `#temas` y `#pedidos`; verificar que el catálogo indica claramente que las compras están desactivadas.
3. Sin sesión: confirmar que no aparecen pedidos ni temas de otra cuenta y que el inicio de sesión se solicita donde corresponda.
4. Con una cuenta sin compras: confirmar estado vacío correcto.
5. Simular error de lectura/RLS y verificar el mensaje y el botón de reintento.
6. Cambiar de cuenta rápidamente mientras se carga el historial; confirmar que una respuesta tardía no mezcla datos entre cuentas.
7. Solo después de que exista un flujo de pago en servidor, probar sandbox de PayPal, webhook/Edge Function, idempotencia, RLS y conciliación de estados.

Esta lista es una guía; no acredita que el hosting, las políticas remotas o el pago hayan sido probados.
