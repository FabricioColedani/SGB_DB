const BACKEND_ORIGIN = window.location.protocol.startsWith('http') ? window.location.origin : 'http://localhost:3000';
const API_BASE = window.location.protocol.startsWith('http') ? '/api' : 'http://localhost:3000/api';

const $ = id => document.getElementById(id);

// Elements
const sourceLabel = $('sourceLabel');
const latencyLabel = $('latencyLabel');
const redisBadge = $('redisBadge');
const mainTitle = $('mainTitle');
const mainContent = $('mainContent');
const chartPosCtx = document.getElementById('chartPos').getContext('2d');
const chartTopCtx = document.getElementById('chartTop').getContext('2d');
const playerInput = $('playerInput');
const playerBtn = $('playerBtn');
const playerResult = $('playerResult');
const redisRanking = $('redisRanking');

let posChart = null;
let topChart = null;

const setStatus = (meta) => {
  if (!meta) return;
  latencyLabel.textContent = `${meta.durationMs ?? '-'} ms`;
  sourceLabel.textContent = meta.cacheHit ? 'Cache HIT (Redis)' : 'Cache MISS (PostgreSQL)';
  if (meta.redisOnline) {
    redisBadge.textContent = 'Redis Online';
    redisBadge.className = 'badge bg-success';
  } else {
    redisBadge.textContent = 'Redis Offline';
    redisBadge.className = 'badge bg-danger';
  }
};

const renderTable = (title, rows) => {
  mainTitle.textContent = title;
  if (!rows || rows.length === 0) {
    mainContent.innerHTML = '<div class="text-muted">No hay datos para mostrar.</div>';
    return;
  }

  const columns = Object.keys(rows[0]);
  const thead = '<div class="table-responsive"><table class="table table-sm"><thead class="table-light"><tr>' + columns.map(c=>`<th>${c}</th>`).join('') + '</tr></thead><tbody>';
  const tbody = rows.map(r=>'<tr>'+columns.map(c=>`<td>${r[c] ?? ''}</td>`).join('')+'</tr>').join('');
  mainContent.innerHTML = thead + tbody + '</tbody></table></div>';
};

const fetchWithMeta = async (path) => {
  const start = performance.now();
  const res = await fetch(path);
  const duration = Math.round(performance.now() - start);
  const payload = await res.json();
  if (!payload.meta) payload.meta = { durationMs: duration, cacheHit: false, redisOnline: payload.redisOnline ?? false };
  if (payload.meta.durationMs == null) payload.meta.durationMs = duration;
  return payload;
};

async function loadPosiciones() {
  try {
    const payload = await fetchWithMeta(`${API_BASE}/posiciones`);
    setStatus(payload.meta);
    renderTable('Tabla de Posiciones', payload.data);
    // chart
    const labels = payload.data.map(r=>r.nombre);
    const puntos = payload.data.map(r=>Number(r.puntos||0));
    if (posChart) posChart.destroy();
    posChart = new Chart(chartPosCtx, {type:'bar', data:{labels, datasets:[{label:'Puntos', data:puntos, backgroundColor:'rgba(79,70,229,0.8)'}]}, options:{responsive:true}});
  } catch (e) {
    mainContent.innerHTML = `<div class="text-danger">Error: ${e.message}</div>`;
  }
}

async function loadTopAnotadores() {
  try {
    const payload = await fetchWithMeta(`${API_BASE}/estadisticas/maximos-anotadores`);
    setStatus(payload.meta);
    renderTable('Máximos Anotadores - Top 10', payload.data);
    const labels = payload.data.map(r=>r.jugador);
    const pts = payload.data.map(r=>Number(r.puntos_totales||0));
    if (topChart) topChart.destroy();
    topChart = new Chart(chartTopCtx, {type:'bar', data:{labels, datasets:[{label:'Puntos Totales', data:pts, backgroundColor:'rgba(34,197,94,0.9)'}]}, options:{responsive:true}});
  } catch (e) {
    mainContent.innerHTML = `<div class="text-danger">Error: ${e.message}</div>`;
  }
}

async function loadEquipos() {
  try {
    const payload = await fetchWithMeta(`${API_BASE}/equipos`);
    setStatus(payload.meta);
    renderTable('Lista de Equipos', payload.data);
  } catch (e) {
    mainContent.innerHTML = `<div class="text-danger">Error: ${e.message}</div>`;
  }
}

async function loadPartidosResumen() {
  try {
    const res = await fetch(`${BACKEND_ORIGIN}/partidos/resumen`);
    const payload = await res.json();
    // /partidos/resumen returns different shape (no meta) so craft meta
    const meta = { durationMs: '-','cacheHit': false, redisOnline: true };
    setStatus(meta);
    renderTable('Partidos - Resumen', payload.data || payload);
  } catch (e) {
    mainContent.innerHTML = `<div class="text-danger">Error: ${e.message}</div>`;
  }
}

async function loadRanking() {
  try {
    const res = await fetch(`${BACKEND_ORIGIN}/ranking`);
    const payload = await res.json();
    setStatus({ durationMs: '-', cacheHit: false, redisOnline: false });
    if (payload.topPlayers) {
      // payload.topPlayers might be array of [member, score] pairs
      const rows = payload.topPlayers.map(item => {
        if (Array.isArray(item)) return { member: item[0], score: item[1] };
        if (item.member) return { member: item.member, score: item.score };
        return item;
      });
      renderTable('Ranking', rows);
      redisRanking.innerHTML = `Top: ${rows.slice(0,5).map(r=>`${r.member} (${r.score})`).join(', ')}`;
    } else {
      mainContent.innerHTML = '<div class="text-muted">No hay datos de ranking</div>';
    }
  } catch (e) {
    redisRanking.textContent = 'No se pudo cargar ranking';
  }
}

const renderPlayerCard = (player, source) => {
  if (!player) return '<div class="text-muted">No hay datos de jugador.</div>';

  const rows = [
    ['ID', player.id],
    ['Nombre', `${player.nombre || ''} ${player.apellido || ''}`.trim()],
    ['Posición', player.posicion || '-'],
    ['Fecha de nacimiento', player.fechaNacimiento || '-'],
    ['Altura', player.altura ? `${player.altura} m` : '-'],
    ['Peso', player.peso ? `${player.peso} kg` : '-'],
    ['Equipo', player.equipo || '-'],
    ['Fuente', source || 'Desconocida']
  ];

  const detailRows = rows.map(([label, value]) => {
    return `<div class="d-flex justify-content-between py-1 border-bottom"><strong>${label}</strong><span>${value}</span></div>`;
  }).join('');

  return `
    <div class="card bg-light p-3">
      <div class="mb-2"><strong>Jugador encontrado</strong></div>
      ${detailRows}
    </div>
  `;
};

async function searchPlayer() {
  const id = playerInput.value.trim();
  if (!id) return;
  playerResult.textContent = 'Buscando...';
  try {
    const res = await fetch(`${BACKEND_ORIGIN}/player/${id}`);
    const payload = await res.json();
    if (res.ok) {
      const player = payload.data || payload;
      const source = payload.source || (payload.meta && payload.meta.cacheHit ? 'Redis' : 'PostgreSQL');
      playerResult.innerHTML = renderPlayerCard(player, source);
    } else {
      playerResult.textContent = payload.message || payload.error || 'No encontrado';
    }
  } catch (e) {
    playerResult.textContent = `Error: ${e.message}`;
  }
}

// Wire UI
$('btnRefreshHealth').addEventListener('click', async ()=>{
  try {
    const res = await fetch(`${API_BASE}/health`);
    const payload = await res.json();
    setStatus({ durationMs: '-', cacheHit: false, redisOnline: payload.redisOnline });
  } catch(e) { setStatus({ durationMs: '-', cacheHit:false, redisOnline:false }); }
});

$('quickPos').addEventListener('click', loadPosiciones);
$('quickTop').addEventListener('click', loadTopAnotadores);
$('quickEq').addEventListener('click', loadEquipos);

$('navPos').addEventListener('click', (e)=>{e.preventDefault(); loadPosiciones();});
$('navTop').addEventListener('click', (e)=>{e.preventDefault(); loadTopAnotadores();});
$('navEquipos').addEventListener('click', (e)=>{e.preventDefault(); loadEquipos();});
$('navPartidos').addEventListener('click', (e)=>{e.preventDefault(); loadPartidosResumen();});
$('navRanking').addEventListener('click', (e)=>{e.preventDefault(); loadRanking();});
playerBtn.addEventListener('click', searchPlayer);

// initial
(async ()=>{
  try { await fetch(`${API_BASE}/health`); } catch(e){}
  // warm-up
  loadPosiciones();
  loadTopAnotadores();
  loadRanking();
})();
