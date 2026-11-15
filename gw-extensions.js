/* Extensión de temas. El catálogo es informativo: no habilita compras ni confirma pagos.
   La propiedad se reconoce solo en pedidos cuyo estado escribió el servidor.
   Depende de los globals definidos en geffenweverse-web-2026-11-14.html. */
(() => {
  'use strict';

  const TEMAS = [
    { key: 'geffenblue', nombre: 'GeffenBlue', colores: ['#06122b', '#0d1f45', '#1e3a78', '#ffffff', '#93a8d6', '#38bdf8', '#2563eb'] },
    { key: 'geffenstar', nombre: 'GeffenStar', colores: ['#120c24', '#1d1438', '#3b2a6b', '#ffffff', '#b3a6d9', '#fde047', '#a78bfa'] },
    { key: 'sumshine', nombre: 'Sumshine', colores: ['#fff8e1', '#ffffff', '#fde68a', '#3b2a05', '#8a6d1d', '#f59e0b', '#f97316'] },
    { key: 'blue-moon', nombre: 'Blue Moon', colores: ['#0a1630', '#12234a', '#26407a', '#eaf2ff', '#8fa6d4', '#7dd3fc', '#3b82f6'] },
    { key: 'dark-moon', nombre: 'Dark Moon', colores: ['#050505', '#121212', '#262626', '#f1f1f1', '#8a8a8a', '#c4b5fd', '#6d28d9'] },
    { key: 'stellar', nombre: 'Stellar', colores: ['#0b0f1f', '#151b33', '#2b3563', '#ffffff', '#9aa5d1', '#fbbf24', '#818cf8'] },
    { key: 'cosmic-love', nombre: 'Cosmic Love', colores: ['#1a0b2e', '#2a1247', '#552a8a', '#fff1f8', '#d1a6e6', '#f472b6', '#c026d3'] },
    { key: 'geffengord', nombre: 'GeffenGord', colores: ['#1c1209', '#2b1c0d', '#5a3a17', '#fff7ed', '#d1a77a', '#fb923c', '#d97706'] },
    { key: 'glue-gorld', nombre: 'Glue Gorld', colores: ['#0f1a0a', '#18260f', '#34521d', '#f3ffe9', '#a3c48a', '#a3e635', '#65a30d'] },
    { key: 'galaxy', nombre: 'Galaxy', colores: ['#070816', '#101230', '#2a2d6b', '#ffffff', '#9a9ed6', '#22d3ee', '#7c3aed'] },
    { key: 'spring', nombre: 'Spring', colores: ['#f3fff4', '#ffffff', '#bbf7d0', '#14321b', '#4d7a58', '#22c55e', '#ec4899'] },
    { key: 'snow', nombre: 'Snow', colores: ['#f4f8fc', '#ffffff', '#d6e4f2', '#0f2236', '#5b7a96', '#38bdf8', '#64748b'] },
    { key: 'winter', nombre: 'Winter', colores: ['#0c1722', '#14263a', '#2b4560', '#eaf4ff', '#8fb0cc', '#7dd3fc', '#38bdf8'] },
    { key: 'summer', nombre: 'Summer', colores: ['#fffbea', '#ffffff', '#fde68a', '#3a2a05', '#8a6d1d', '#fb923c', '#06b6d4'] },
    { key: 'rainbow-geffen', nombre: 'Rainbow Geffen', colores: ['#0d0d12', '#17171f', '#34343f', '#ffffff', '#a0a0b0', '#f43f5e', '#8b5cf6'] }
  ].map(t => ({ ...t, vars: Object.fromEntries(['--bg', '--card', '--line', '--tx', '--mu', '--ac', '--brand'].map((v, i) => [v, t.colores[i]])) }));

  const PAGADOS = new Set(['Pagado', 'Completado']);
  const byKey = key => TEMAS.find(t => t.key === key);
  const nombreProducto = tema => 'Tema ' + tema.nombre;
  const VARS = ['--bg', '--card', '--line', '--tx', '--mu', '--ac', '--brand'];
  let owned = new Set();
  let loadedFor = null;
  let loading = null;
  let loadingFor = null;
  let requestVersion = 0;
  let lastLoad = 0;
  let loadState = 'idle';

  const claveActivo = () => 'tema-activo-' + (currentUser?.id || 'anon');
  const fechaLocal = value => {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? 'Fecha no disponible' : date.toLocaleDateString('es-DO');
  };

  function limpiarTema() {
    VARS.forEach(v => document.documentElement.style.removeProperty(v));
    document.documentElement.removeAttribute('data-gw-tema');
  }

  function aplicarTema() {
    const tema = byKey(J.get(claveActivo(), null));
    if (!tema || !owned.has(tema.key)) return limpiarTema();
    VARS.forEach(v => document.documentElement.style.setProperty(v, tema.vars[v]));
    document.documentElement.setAttribute('data-gw-tema', tema.key);
  }

  function vaciarPedidos() {
    pedidos.length = 0;
  }

  async function cargarPedidos(force = false) {
    const userId = currentUser?.id || null;
    if (!userId) {
      requestVersion++;
      owned = new Set();
      loadedFor = null;
      loading = null;
      loadingFor = null;
      loadState = 'idle';
      vaciarPedidos();
      aplicarTema();
      return;
    }
    if (loading && loadingFor === userId) return loading;
    if (!force && loadedFor === userId && Date.now() - lastLoad < 30000) return;

    const version = ++requestVersion;
    loadingFor = userId;
    loadState = 'loading';
    loading = (async () => {
      try {
        const { data, error } = await supabaseClient
          .from('orders')
          .select('id, estado, total, metodo, created_at, order_items(nombre, cantidad)')
          .order('created_at', { ascending: false });
        if (error) throw error;

        // Ignora resultados tardíos de una cuenta anterior o de una solicitud reemplazada.
        if (version !== requestVersion || currentUser?.id !== userId) return;
        const rows = data || [];
        const nuevos = new Set();
        const nuevosPedidos = rows.map(o => {
          const items = o.order_items || [];
          if (PAGADOS.has(o.estado)) {
            items.forEach(item => {
              const tema = TEMAS.find(t => nombreProducto(t) === item.nombre);
              if (tema) nuevos.add(tema.key);
            });
          }
          return {
            id: String(o.id).slice(0, 8).toUpperCase(),
            fecha: fechaLocal(o.created_at),
            estado: o.estado,
            total: usd(o.total),
            articulos: items.map(item => item.nombre + (item.cantidad > 1 ? ' x' + item.cantidad : '')).join(', ') || 'Sin artículos'
          };
        });

        pedidos.splice(0, pedidos.length, ...nuevosPedidos);
        owned = nuevos;
        loadedFor = userId;
        lastLoad = Date.now();
        loadState = 'ready';
      } catch (error) {
        if (version === requestVersion && currentUser?.id === userId) {
          console.error('GeffenWeverse · no se pudieron cargar los pedidos:', error);
          owned = new Set();
          loadedFor = null;
          vaciarPedidos();
          loadState = 'error';
        }
      } finally {
        if (version === requestVersion) {
          loading = null;
          loadingFor = null;
          aplicarTema();
          const route = location.hash.slice(1);
          if (['pedidos', 'temas', 'tienda-temas'].includes(route)) render();
        }
      }
    })();
    return loading;
  }

  function estadoCarga() {
    if (loadState === 'loading' || loadState === 'idle') return '<p class="mu" role="status">Verificando tus temas…</p>';
    if (loadState === 'error') return '<div class="empty" role="alert"><p>No se pudieron cargar tus pedidos.</p><button class="pill" type="button" data-gw-retry>Reintentar</button></div>';
    return '';
  }

  const swatches = tema => `<div aria-label="Colores del tema" style="display:flex;gap:6px;margin-top:12px">${[tema.vars['--bg'], tema.vars['--card'], tema.vars['--ac'], tema.vars['--brand']].map(color => `<span aria-hidden="true" style="width:22px;height:22px;border-radius:50%;background:${color};border:1px solid #8884"></span>`).join('')}</div>`;
  const tarjetaTema = tema => `<article class="ord" style="align-items:flex-start;background:linear-gradient(135deg,${tema.vars['--bg']},${tema.vars['--card']});color:${tema.vars['--tx']};border:1px solid ${tema.vars['--line']}"><div><b>${esc(tema.nombre)}</b>${swatches(tema)}</div>${owned.has(tema.key) ? '<span class="pill">Comprado</span>' : '<span class="pill" aria-label="Compra no disponible">No disponible</span>'}</article>`;

  // El catálogo no se agrega a productos: wishlist/checkout no deben insinuar compras habilitadas.
  pages['tienda-temas'] = () => `<div class="lt">${tiendaTop('comprar')}<main class="shop"><div class="fila"><div><h1>Temas</h1><p class="mu" style="margin:6px 0 0">Catálogo informativo · las compras están desactivadas temporalmente</p></div>${herramientas(false)}</div><p class="mu" style="margin:14px 0 4px">La compra y activación estarán disponibles cuando el pago se verifique de forma segura en el servidor.</p>${currentUser ? estadoCarga() : '<p class="mu">Inicia sesión para consultar tus temas adquiridos.</p>'}<div class="cols" style="gap:12px;margin-top:10px">${TEMAS.map(tarjetaTema).join('')}</div></main>${upBtn}</div>`;

  pages.temas = () => {
    const activo = J.get(claveActivo(), null);
    const mios = TEMAS.filter(t => owned.has(t.key));
    const fila = (key, nombre, detalle, disabled = false) => `<div class="row"><span class="t"><b>${esc(nombre)}</b>${detalle ? `<small>${detalle}</small>` : ''}</span><button class="pill" type="button" data-gw-tema="${key}" ${disabled ? 'disabled' : ''}>${disabled ? 'En uso' : 'Usar'}</button></div>`;
    return `<div class="wrap">${barra('Temas', 'Tus temas comprados', '#configuracion')}<section class="card">${estadoCarga()}${fila('', 'Predeterminado', 'Claro, oscuro o del dispositivo (ver Pantalla)', !activo)}${mios.map(t => fila(t.key, t.nombre, 'Comprado', activo === t.key)).join('')}${loadState === 'ready' && !mios.length ? '<p class="mu">Aún no tienes temas adquiridos.</p>' : ''}${currentUser ? '' : vacio('Inicia sesión para consultar tus temas.')}</section><section class="card"><a class="row" href="#tienda-temas"><span class="t"><b>Ver catálogo de temas</b><small>Las compras están desactivadas temporalmente.</small></span>${I('chev', 'chev')}</a></section></div>`;
  };

  pages.pedidos = () => `<div class="lt">${tiendaTop('pedidos')}<main class="shop"><h1>Mis Pedidos</h1><p class="mu" style="margin:6px 0 0">El historial se muestra solo para la cuenta autenticada.</p>${estadoCarga()}${loadState === 'ready' ? pedidos.length ? pedidos.map(p => `<article class="ord"><div><b>Pedido ${esc(p.id)}</b><div class="mu">${esc(p.fecha)} · ${esc(p.articulos)} · ${esc(p.metodo || 'PayPal')}</div></div><div style="text-align:right"><b style="color:var(--brand)">${esc(p.estado)}</b><div><b>${esc(p.total)}</b></div></div></article>`).join('') : '<section class="empty"><p>No hay pedidos.</p></section>' : ''}</main>${upBtn}</div>`;

  const radioFix = html => html.replace(/Starship Listing Party/g, 'Geffen Radio').replace(/<b>Radio FM<\/b>/g, '<b>Geffen Radio</b>');
  const envolver = (key, fn) => {
    const original = pages[key];
    if (typeof original === 'function') pages[key] = (...args) => fn(original(...args));
  };
  envolver('comprar', html => html.replace('<section class="card faq">', `<section class="card"><a class="usr" href="#tienda-temas"><span class="av g3"></span><div style="flex:1"><b>Catálogo de temas</b><span class="mu">Compras desactivadas temporalmente</span></div>${I('chev', 'chev')}</a></section><section class="card faq">`));
  envolver('configuracion', html => radioFix(html).replace('<section class="card"><h2>Configuración de complementos</h2>', `<section class="card"><h2>Temas</h2><a class="row" href="#temas"><span class="t"><b>Mis temas</b><small>Consulta los temas adquiridos</small></span>${I('chev', 'chev')}</a></section><section class="card"><h2>Configuración de complementos</h2>`));
  ['inicio', 'feed', 'menu'].forEach(key => envolver(key, radioFix));

  document.addEventListener('click', event => {
    const retry = event.target.closest('[data-gw-retry]');
    if (retry) { cargarPedidos(true); return; }
    const button = event.target.closest('[data-gw-tema]');
    if (!button) return;
    const key = button.dataset.gwTema;
    if (key && !owned.has(key)) { toast('Este tema no está disponible en tu cuenta.'); return; }
    J.set(claveActivo(), key || null);
    aplicarTema();
    render();
    toast(key ? 'Tema aplicado' : 'Tema predeterminado');
  });

  addEventListener('hashchange', () => {
    const route = location.hash.slice(1);
    if (['pedidos', 'temas', 'tienda-temas'].includes(route)) cargarPedidos(false);
  });

  try {
    supabaseClient.auth.onAuthStateChange(() => { setTimeout(() => cargarPedidos(true), 0); });
  } catch (error) {
    console.warn('GeffenWeverse · no fue posible registrar el cambio de sesión:', error);
  }

  cargarPedidos(true);
  render();
})();
