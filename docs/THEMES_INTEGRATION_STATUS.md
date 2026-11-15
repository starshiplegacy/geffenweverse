# Estado de integración: temas y pedidos

Última revisión: 2026-11-15.

## Estado seguro actual

- `index.html` carga la interfaz oficial y añade `gw-extensions.js` después del script principal.
- La extensión presenta un catálogo informativo; **no habilita compras, checkout ni aceptación de pagos**.
- La lista de temas adquiridos se deriva de pedidos leídos para la sesión actual. La interfaz nunca debe cambiar un pedido a pagado.
- El SQL `20261115120000_temas_catalogo.sql` sigue pendiente de reconciliación con el historial real de Supabase. No ejecutarlo ni duplicarlo hasta confirmar el flujo oficial de migraciones.
- GitHub Pages: despliegue verificado correctamente el 2026-11-15 (workflow run [43699324565](https://github.com/starshiplegacy/geffenweverse/actions/runs/43699324565)); la URL pública respondió HTTP 200.
- Se verificó visualmente la pantalla inicial de acceso en navegador automatizado y se validó la sintaxis JavaScript del HTML principal y de la extensión. No se ha realizado todavía una prueba completa con sesión autenticada ni una inspección de consola del navegador.

## Dependencias del HTML oficial

La extensión espera que `geffenweverse-web-2026-11-14.html` cargue primero y defina `productos`, `pedidos`, `currentUser`, `supabaseClient`, `pages`, `J`, `I`, `esc`, `usd`, `toast`, `render`, `tiendaTop`, `herramientas`, `barra`, `vacio` y `upBtn`. Si cambia el HTML de referencia, volver a validar este contrato antes de publicar.

## Pruebas manuales antes de publicar

1. Revisar en un navegador real la consola y la carga de `gw-extensions.js` en desktop y móvil.
2. Probar ruta inicial, `#tienda-temas`, `#temas` y `#pedidos`; verificar que el catálogo indica claramente que las compras están desactivadas.
3. Sin sesión: confirmar que no aparecen pedidos ni temas de otra cuenta y que el inicio de sesión se solicita donde corresponda.
4. Con una cuenta sin compras: confirmar estado vacío correcto.
5. Simular error de lectura/RLS y verificar el mensaje y el botón de reintento.
6. Cambiar de cuenta rápidamente mientras se carga el historial; confirmar que una respuesta tardía no mezcla datos entre cuentas.
7. Solo después de que exista un flujo de pago en servidor, probar sandbox de PayPal, webhook/Edge Function, idempotencia, RLS y conciliación de estados.

Esta lista es una guía; la comprobación HTTP y visual de la pantalla inicial no acredita que todas las rutas, las políticas remotas, la mensajería autenticada o el pago hayan sido probados.

## Presentación de temas adquiridos

- Los pedidos autenticados se leen desde `orders` con sus `order_items`; RLS limita la consulta a los pedidos de la cuenta actual.
- Un tema solo se considera adquirido cuando el pedido está en estado `Pagado` o `Completado`; en **Mis Pedidos** el artículo se marca como **Adquirido**.
- Los temas adquiridos aparecen como opciones seleccionables en **Configuración → Temas del dispositivo**, junto a **Blanco**, **Negro** y **Del dispositivo**.
- La selección de un tema comprado se guarda localmente por cuenta; volver a elegir una de las tres opciones predeterminadas desactiva el tema comprado.
- Esto no habilita el checkout: el catálogo sigue siendo informativo y no permite realizar nuevas compras hasta contar con verificación de pago del lado del servidor.
