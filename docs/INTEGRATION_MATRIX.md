# GeffenWeverse — matriz de integración

**Versión de interfaz de referencia:** [geffenweverse-web-2026-11-14.html](../geffenweverse-web-2026-11-14.html)  
**Rama revisada:** `main`  
**Estado:** auditoría inicial; la interfaz aún no está conectada al backend.

Esta matriz separa lo que el HTML presenta hoy de lo que existe en Supabase. Que una tabla exista no significa que la pantalla ya la esté utilizando.

## Estado general

| Área | Estado comprobado | Próximo trabajo |
|---|---|---|
| Interfaz | HTML/CSS/JS en un único archivo | Mantener el diseño y dividir responsabilidades solo si aporta seguridad y mantenimiento |
| Cliente Supabase | No se encontró inicialización de cliente en el HTML | Añadir cliente con URL y clave publishable mediante configuración pública |
| Autenticación | `Auth.start()` solo navega a otra pantalla | Implementar registro, login, OAuth configurado, sesión persistente y logout |
| Persistencia | Preferencias y datos de ejemplo usan `localStorage` | Sincronizar datos de cuenta con Supabase; conservar localmente solo preferencias no sensibles si conviene |
| Base de datos | 19 tablas públicas observadas; RLS habilitado | Validar políticas por operación antes de conectar cada pantalla |
| Edge Functions | No hay funciones desplegadas | Crear endpoints seguros para operaciones privilegiadas |
| Despliegue web | No se encontró `index.html` ni configuración de hosting en la raíz | Elegir proveedor y definir entrada de producción antes de publicar |

## Matriz pantalla por pantalla

| Pantalla / módulo | Tablas / servicios objetivo | Operaciones requeridas | Estado actual y pendiente |
|---|---|---|---|
| Registro / Login / Logout | Supabase Auth, `profiles`, `user_settings` | `signUp`, `signInWithPassword` u OAuth, recuperar sesión, escuchar cambios, `signOut` | **Simulado.** `Auth.start()` solo navega. El trigger `private.handle_new_user()` crea perfil y ajustes al registrarse. |
| Selección de rol | `profiles.rol` | Leer y guardar `astroturista` o `estrella` en el perfil autenticado | **Solo local.** Hoy se guarda en `localStorage`; debe persistirse en el perfil para que las políticas de publicaciones y Shorts reconozcan el rol. |
| Inicio / Feed | `posts`, `profiles`, `follows`, `comments`, `starlights` | Consultar feed, autor, medios, comentarios y reacciones; paginar por fecha | **Contenido de muestra.** La tarjeta principal y los clips visuales no son publicaciones reales. |
| Mi perfil | `profiles`, `posts`, `follows`, `comments`, `starlights` | Consultar perfil y conteos; actualizar nombre visible, biografía y avatar; listar publicaciones | **Datos ficticios.** “Profile Name”, contadores y publicación de ejemplo deben sustituirse por datos del usuario. |
| Siguiendo / Seguidores | `follows`, `profiles` | Listar relaciones, seguir y dejar de seguir | **Listas estáticas.** La tabla y sus políticas ya existen. |
| Artistas | `artists` | Leer artistas activos ordenados por `orden` | **Array local.** Conectar a la tabla. |
| WikiGeffen | `artists` y contenido editorial por definir | Consultar ficha, biografía, trayectoria, discografía y galería | **Plantilla vacía.** La tabla `artists` solo contiene slug, nombre, tipo, orden y estado; hacen falta campos o tablas editoriales para las secciones de la Wiki. |
| Comunidades | `artists`, `community_members` | Listar comunidades, consultar membresía, unirse y salir | **Solo local.** `community_members` y sus políticas ya existen. |
| Buscar | `artists`, `profiles`, `posts`, `faq` | Buscar por texto y devolver resultados enlazados | **Solo arrays locales.** Conectar búsqueda a las tablas; definir límites y paginación. |
| Crear publicación | `posts`, `profiles`, Storage por definir | Crear texto/foto/video; validar autor y rol | **“Próximamente”.** La tabla permite posts y la política exige rol `estrella`; falta flujo de carga de medios y formulario. |
| Comentarios / Respuestas | `comments`, `profiles` | Crear, listar y borrar comentarios propios; responder mediante `parent_id` | **Sin integración.** Tabla y políticas existen; verificar que cada comentario apunte a un post o Short según el constraint actual. |
| Starlights | `starlights`, `posts`, `comments`, `shorts` | Dar/quitar Starlight y mostrar conteos | **Simulado o sin acción real.** La tabla admite exactamente un destino entre publicación, comentario o Short. |
| Shorts | `shorts`, `profiles`, `starlights`, `comments`, Storage bucket `shorts` | Listar vídeos, subir, borrar propio, comentar, reaccionar y seguir autor | **Tres Shorts de ejemplo.** El bucket existe y es público; el límite configurado es 50 MiB y acepta MP4, WebM y QuickTime. La UI todavía no reproduce vídeos reales ni conecta acciones. |
| Notificaciones | `notifications`, `profiles` | Listar las propias, marcar leída y filtrar por tipo | **Seis notificaciones ficticias.** Las políticas de lectura/actualización propias existen. Triggers crean avisos de follow, comentario y Starlight. |
| Configuración | `user_settings` | Leer y actualizar idioma, traducción, tema, radio y preferencias | **Solo local.** El trigger de alta crea la fila de ajustes; sincronizarla con la sesión. |
| Solicitudes de eventos | `event_requests` | Insertar solicitud y consultar solicitudes propias | **Solo local.** La tabla y políticas de inserción/lectura propias existen. |
| Canje de códigos | `digital_codes`, `purchased_media` | Validar código, impedir doble canje y registrar compra | **Código de demostración hardcodeado.** `digital_codes` no tiene políticas RLS; mantenerla inaccesible al cliente y hacer el canje en servidor/Edge Function o RPC privada. |
| Multimedia comprada | `purchased_media` | Listar contenido desbloqueado por el usuario | **Solo local.** La tabla tiene política de lectura propia; falta el flujo de canje seguro. |
| Cupones | `coupons` | Listar cupones del usuario y comprobar vencimiento | **Array vacío.** La tabla y la política de lectura propia existen. |
| Anuncios | `announcements` | Leer anuncios publicados | **Un anuncio estático.** Existe política de lectura pública. |
| FAQ | `faq` | Leer preguntas y respuestas ordenadas | **Contenido hardcodeado.** Existe política de lectura pública. |
| Comprar / Catálogo | `products` | Listar productos activos, filtrar por categoría y consultar precio | **Array vacío.** Existe tabla y política de lectura pública. |
| Lista de deseos | `wishlist`, `products` | Añadir, quitar, seleccionar y consultar productos del usuario | **Solo local.** Tabla y políticas privadas por usuario existen. |
| Pagar selección | `orders`, `order_items`, PayPal | Crear orden pendiente, iniciar checkout, verificar pago en servidor y actualizar estado | **No implementado.** El botón solo muestra un aviso. No hay Edge Functions desplegadas; no aceptar pagos ni marcar pedidos como pagados desde el navegador. |
| Mis pedidos | `orders`, `order_items` | Consultar pedidos y sus artículos propios | **Array vacío.** Hay políticas de lectura propia; falta crear órdenes mediante backend seguro. |
| GeffenWeverse Spot / Magazine / Concerts / Survey | Esquema por definir | Definir contenido, permisos y operaciones | **Pantallas “Próximamente”.** No hay tablas específicas verificadas para estos módulos. |

## Hallazgos de seguridad y backend

1. **RLS:** las 19 tablas públicas observadas tienen RLS habilitado.
2. **Códigos digitales:** el asesor de Supabase detecta `public.digital_codes` con RLS habilitado y sin políticas. Esto bloquea el acceso por Data API y es adecuado mientras los códigos se gestionen exclusivamente desde servidor. No añadir una política pública para “arreglar” el aviso.
3. **Shorts Storage:** bucket `shorts` configurado como público, con máximo de 50 MiB y MIME types `video/mp4`, `video/webm`, `video/quicktime`. La política de carga exige carpeta inicial igual al UID y rol `estrella`; la política de borrado limita al propietario. Al ser público, los archivos publicados pueden servirse mediante URL pública.
4. **Pagos:** `orders` y `order_items` solo muestran políticas de lectura en el esquema observado. El navegador no debe insertar órdenes pagadas ni decidir el estado final del pago.
5. **Funciones:** no hay Supabase Edge Functions desplegadas en el proyecto consultado.
6. **Migraciones:** Supabase registra `20261114072453 geffenweverse_esquema_inicial`, `20261114072522 cerrar_acceso_publico_rls_auto_enable` y `20261114073731 shorts_videos_verticales`. En GitHub se ven dos archivos SQL con prefijos distintos. La migración `cerrar_acceso_publico_rls_auto_enable` no tiene todavía un archivo fuente identificado en el repositorio. No volver a ejecutar los SQL existentes ni reconstruir esa migración por su nombre: primero recuperar su definición aplicada.
7. **Claves:** el frontend podrá usar únicamente una clave publishable. Nunca incluir `service_role`, claves secretas de PayPal ni contraseñas en el HTML o en GitHub.

## Orden recomendado de implementación

1. Recuperar y documentar la migración aplicada que falta en GitHub; verificar historial y esquema sin volver a aplicar scripts.
2. Preparar configuración de entorno y cliente Supabase con clave publishable.
3. Implementar Auth, recuperación de sesión, logout y persistencia del rol.
4. Conectar perfiles, artistas, comunidades, follows y feed.
5. Conectar publicaciones, comentarios, Starlights, Shorts y notificaciones.
6. Conectar ajustes, eventos, FAQ, anuncios, códigos y multimedia comprada.
7. Implementar catálogo, wishlist y checkout con validación de pagos en servidor.
8. Elegir hosting, definir entrada de producción, probar flujos con cuentas de prueba y revisar RLS/advisors antes de publicar.

## Reglas para mantener el proyecto seguro

- No borrar ni sobrescribir el HTML de respaldo `geffenweverse-web.html`.
- La interfaz de referencia es `geffenweverse-web-2026-11-14.html`.
- No guardar secretos ni claves privilegiadas en el navegador.
- No conceder acceso a `digital_codes` desde el cliente.
- No marcar una orden como pagada basándose solo en una respuesta del navegador.
- No aplicar migraciones hasta reconciliar el historial real de Supabase con los archivos del repositorio.
- Mantener el diseño actual; los cambios visuales deben ser pequeños y respaldados por una necesidad de usabilidad o accesibilidad.
