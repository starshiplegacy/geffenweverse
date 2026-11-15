(() => {
  'use strict';
  const PRECIO = 4;
  const T = (key, nombre, bg, card, line, tx, mu, ac, brand) => ({ key, nombre, v: { '--bg': bg, '--card': card, '--line': line, '--tx': tx, '--mu': mu, '--ac': ac, '--brand': brand } });
  const TEMAS = [
    T('geffenblue', 'GeffenBlue', '#06122b', '#0d1f45', '#1e3a78', '#ffffff', '#93a8d6', '#38bdf8', '#2563eb'),
    T('geffenstar', 'GeffenStar', '#120c24', '#1d1438', '#3b2a6b', '#ffffff', '#b3a6d9', '#fde047', '#a78bfa'),
    T('sumshine', 'Sumshine', '#fff8e1', '#ffffff', '#fde68a', '#3b2a05', '#8a6d1d', '#f59e0b', '#f97316'),
    T('blue-moon', 'Blue Moon', '#0a1630', '#12234a', '#26407a', '#eaf2ff', '#8fa6d4', '#7dd3fc', '#3b82f6'),
    T('dark-moon', 'Dark Moon', '#050505', '#121212', '#262626', '#f1f1f1', '#8a8a8a', '#c4b5fd', '#6d28d9'),
    T('stellar', 'Stellar', '#0b0f1f', '#151b33', '#2b3563', '#ffffff', '#9aa5d1', '#fbbf24', '#818cf8'),
    T('cosmic-love', 'Cosmic Love', '#1a0b2e', '#2a1247', '#552a8a', '#fff1f8', '#d1a6e6', '#f472b6', '#c026d3'),
    T('geffengord', 'GeffenGord', '#1c1209', '#2b1c0d', '#5a3a17', '#fff7ed', '#d1a77a', '#fb923c', '#d97706'),
    T('glue-gorld', 'Glue Gorld', '#0f1a0a', '#18260f', '#34521d', '#f3ffe9', '#a3c48a', '#a3e635', '#65a30d'),
    T('galaxy', 'Galaxy', '#070816', '#101230', '#2a2d6b', '#ffffff', '#9a9ed6', '#22d3ee', '#7c3aed'),
    T('spring', 'Spring', '#f3fff4', '#ffffff', '#bbf7d0', '#14321b', '#4d7a58', '#22c55e', '#ec4899'),
    T('snow', 'Snow', '#f4f8fc', '#ffffff', '#d6e4f2', '#0f2236', '#5b7a96', '#38bdf8', '#64748b'),
    T('winter', 'Winter', '#0c1722', '#14263a', '#2b4560', '#eaf4ff', '#8fb0cc', '#7dd3fc', '#38bdf8'),
    T('summer', 'Summer', '#fffbea', '#ffffff', '#fde68a', '#3a2a05', '#8a6d1d', '#fb923c', '#06b6d4'),
    T('rainbow-geffen', 'Rainbow Geffen', '#0d0d12', '#17171f', '#34343f', '#ffffff', '#a0a0b0', '#f43f5e', '#8b5cf6')
  ];
  const byKey = k => TEMAS.find(t => t.key === k);
  const prodId = t => 'tema-' + t.key;
  const prodNombre = t => 'Tema ' + t.nombre;
  const VARS = ['--bg', '--card', '--line', '--tx', '--mu', '--ac', '--brand'];

  /* Productos de la tienda (alimentan el corazón/lista de deseos existente) */
  TEMAS.forEach(t => { if (!productos.some(p => p.id === prodId(t))) productos.push({ id: prodId(t), cat: 'temas', nombre: prodNombre(t), precio: PRECIO }); });

  /* ---- Propiedad de temas y pedidos (lectura desde Supabase; RLS ya limita a las filas del usuario) ---- */
  const PAGADOS = ['Pagado', 'Completado'];
  let owned = new Set(), loadedFor = null, loading = null, lastLoad = 0;
  const fmtFecha = iso => { try { return new Date(iso).toLocaleDateString('es-DO'); } catch (e) { return ''; } };
  async function cargar(force) {
    if (!currentUser) { owned = new Set(); loadedFor = null; aplicarActivo(); return; }
    if (loading) return loading;
    if (!force && loadedFor === currentUser.id && Date.now() - lastLoad < 30000) return;
    loading = (async () => {
      try {
        const { data, error } = await supabaseClient.from('orders').select('id, estado, total, metodo, created_at, order_items(nombre, cantidad)').order('created_at', { ascending: false });
        if (error) throw error;
        const nuevos = new Set();
        pedidos.length = 0;
        (data || []).forEach(o => {
          const items = o.order_items || [];
          if (PAGADOS.includes(o.estado)) items.forEach(i => { const t = TEMAS.find(x => prodNombre(x) === i.nombre); if (t) nuevos.add(t.key); });
          pedidos.push({ id: String(o.id).slice(0, 8).toUpperCase(), fecha: fmtFecha(o.created_at), estado: o.estado, total: usd(o.total), articulos: items.map(i => i.nombre + (i.cantidad > 1 ? ' x' + i.cantidad : '')).join(', ') || 'Sin artículos' });
        });
        owned = nuevos; loadedFor = currentUser.id; lastLoad = Date.now();
      } catch (e) { console.error('GeffenWeverse · pedidos/temas:', e); }
      finally { loading = null; aplicarActivo(); const r = location.hash.slice(1); if (['pedidos', 'temas', 'tienda-temas'].includes(r)) render(); }
    })();
    return loading;
  }

  /* ---- Aplicar tema ---- */
  const claveActivo = () => 'tema-activo-' + (currentUser?.id || 'anon');
  function limpiar() { VARS.forEach(v => document.documentElement.style.removeProperty(v)); document.documentElement.removeAttribute('data-gw-tema'); }
  function aplicarActivo() {
    const k = J.get(claveActivo(), null), t = k && byKey(k);
    if (t && owned.has(t.key)) { VARS.forEach(v => document.documentElement.style.setProperty(v, t.v[v])); document.documentElement.setAttribute('data-gw-tema', t.key); }
    else limpiar();
  }

  /* ---- Piezas visuales ---- */
  const swatch = t => `<div style="display:flex;gap:6px;margin-top:12px">${[t.v['--bg'], t.v['--card'], t.v['--ac'], t.v['--brand']].map(c => `<span style="width:22px;height:22px;border-radius:50%;background:${c};border:1px solid #8884"></span>`).join('')}</div>`;
  const tarjetaTema = t => {
    const fav = J.get('deseos', []).some(x => x.id === prodId(t)), tiene = owned.has(t.key);
    return `<article class="ord" style="align-items:flex-start;background:linear-gradient(135deg,${t.v['--bg']},${t.v['--card']});color:${t.v['--tx']};border:1px solid ${t.v['--line']}"><div><b>${esc(t.nombre)}</b><div style="opacity:.75;font-size:12px">${usd(PRECIO)}</div>${swatch(t)}</div>${tiene ? '<span class="pill">Comprado</span>' : `<button class="heart ${fav ? 'on' : ''}" data-act="deseo" data-id="${prodId(t)}" aria-label="Guardar ${esc(t.nombre)} en la lista de deseos">${I('heart')}</button>`}</article>`;
  };

  /* ---- Páginas ---- */
  pages['tienda-temas'] = () => `<div class="lt">${tiendaTop('comprar')}
    <main class="shop"><div class="fila"><div><h1>Temas</h1><p class="mu" style="margin:6px 0 0">Personaliza GeffenWeverse · USD ${PRECIO.toFixed(2)} cada uno</p></div>${herramientas(false)}</div>
    <p class="mu" style="margin:14px 0 4px">Tras pagar con PayPal, tus temas aparecen en <a href="#pedidos">Mis Pedidos</a> y en <a href="#temas">Configuración → Temas</a>.</p>
    <div class="cols" style="gap:12px;margin-top:10px">${TEMAS.map(tarjetaTema).join('')}</div></main>${upBtn}</div>`;

  pages.temas = () => {
    const activo = J.get(claveActivo(), null);
    const mios = TEMAS.filter(t => owned.has(t.key));
    const fila = (k, nombre, extra) => `<div class="row"><span class="t"><b>${esc(nombre)}</b>${extra ? `<small>${extra}</small>` : ''}</span><button class="pill" data-gw-tema="${k}" ${(activo || '') === k ? 'disabled' : ''}>${(activo || '') === k ? 'En uso' : 'Usar'}</button></div>`;
    return `<div class="wrap">${barra('Temas', 'Tus temas comprados', '#configuracion')}
      <section class="card">${fila('', 'Predeterminado', 'Claro, oscuro o del dispositivo (ver Pantalla)')}${mios.map(t => fila(t.key, t.nombre, 'Comprado')).join('')}${currentUser ? '' : vacio('Inicia sesión para ver tus temas.')}</section>
      <section class="card"><a class="row" href="#tienda-temas"><span class="t"><b>${mios.length ? 'Conseguir más temas' : 'Aún no tienes temas'}</b><small>Geffen Shop · USD ${PRECIO.toFixed(2)} cada uno</small></span>${I('chev', 'chev')}</a></section></div>`;
  };

  /* ---- Envolver páginas existentes sin tocar el HTML oficial ---- */
  const radioFix = h => h.replace(/Starship Listing Party/g, 'Geffen Radio').replace(/<b>Radio FM<\/b>/g, '<b>Geffen Radio</b>');
  const envolver = (k, fn) => { const o = pages[k]; if (typeof o === 'function') pages[k] = (...a) => fn(o(...a)); };
  envolver('comprar', h => h.replace('<section class="card faq">', `<section class="card"><a class="usr" href="#tienda-temas"><span class="av g3"></span><div style="flex:1"><b>Temas</b><span class="mu">GeffenBlue, Galaxy, Rainbow Geffen y más · USD ${PRECIO.toFixed(2)}</span></div>${I('chev', 'chev')}</a></section><section class="card faq">`));
  envolver('configuracion', h => radioFix(h).replace('<section class="card"><h2>Configuración de complementos</h2>', `<section class="card"><h2>Temas</h2><a class="row" href="#temas"><span class="t"><b>Mis temas</b><small>Activa los temas que compraste en Geffen Shop</small></span>${I('chev', 'chev')}</a></section><section class="card"><h2>Configuración de complementos</h2>`));
  ['inicio', 'feed', 'menu'].forEach(k => envolver(k, radioFix));

  /* ---- Eventos ---- */
  document.addEventListener('click', e => {
    const b = e.target.closest('[data-gw-tema]'); if (!b) return;
    const k = b.dataset.gwTema;
    if (k && !owned.has(k)) { toast('Primero compra este tema en Geffen Shop'); return; }
    J.set(claveActivo(), k || null); aplicarActivo(); render();
    toast(k ? 'Tema aplicado' : 'Tema predeterminado');
  });
  addEventListener('hashchange', () => { const r = location.hash.slice(1); if (['pedidos', 'temas', 'tienda-temas', 'configuracion'].includes(r)) cargar(false); });
  try { supabaseClient.auth.onAuthStateChange(() => { cargar(true); }); } catch (e) { /* sin sesión */ }
  cargar(true); render();
})();
