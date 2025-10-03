document.addEventListener('htmx:afterOnLoad', () => {
  const route = window.location.pathname + window.location.search;
  const links = document.querySelectorAll('#sidebar-menu a');
  links.forEach(a => {
    const match = a.getAttribute('data-route');
    if (match && route.startsWith(match)) {
      a.classList.add('active');
    } else {
      a.classList.remove('active');
    }
  });
});

window.addEventListener('DOMContentLoaded', () => {
  const initial = document.querySelector('#sidebar-menu a');
  const content = document.querySelector('#content');
  if (initial && content && content.children.length === 0) {
    initial.click();
  }

  // Theme toggle
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'dark') document.body.classList.add('dark');
  document.getElementById('theme-toggle')?.addEventListener('click', () => {
    document.body.classList.toggle('dark');
    localStorage.setItem('theme', document.body.classList.contains('dark') ? 'dark' : 'light');
  });

  // Table search filter
  document.addEventListener('input', (e) => {
    const target = e.target;
    if (!(target instanceof HTMLInputElement)) return;
    if (!target.classList.contains('table-search')) return;
    const section = target.closest('.section') || document;
    const table = section.querySelector('table');
    if (!table) return;
    const q = target.value.trim().toLowerCase();
    const rows = table.querySelectorAll('tbody tr');
    rows.forEach(row => {
      const text = row.textContent?.toLowerCase() || '';
      row.classList.toggle('hidden', q.length > 0 && !text.includes(q));
    });
  });

  // HTMX loading overlay + toasts
  let overlay;
  document.body.addEventListener('htmx:beforeRequest', (evt) => {
    const tgt = document.getElementById('content');
    overlay = document.createElement('div');
    overlay.className = 'loading-overlay';
    overlay.innerHTML = '<div class="spinner mono">Loading…</div>';
    tgt?.appendChild(overlay);
  });
  document.body.addEventListener('htmx:afterSwap', () => { overlay?.remove(); });
  document.body.addEventListener('htmx:responseError', (evt) => {
    overlay?.remove();
    showToast('Request failed. Please try again.', 'error');
  });

  // Modern confirm for destructive actions
  document.addEventListener('click', async (e) => {
    const btn = e.target.closest('button[data-confirm]');
    if (!btn) return;
    e.preventDefault();
    const msg = btn.getAttribute('data-confirm') || 'Are you sure?';
    const ok = await confirmModal(msg);
    if (!ok) return;
    const form = btn.closest('form');
    if (form) {
      if (window.htmx) {
        window.htmx.trigger(form, 'submit');
      } else {
        form.submit();
      }
    }
  });

  // Background particles
  const canvas = document.getElementById('bg-particles');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const DPR = Math.min(window.devicePixelRatio || 1, 2);
  const colors = [
    'rgba(37, 99, 235, 0.12)',
    'rgba(34, 197, 94, 0.12)',
    'rgba(99, 102, 241, 0.12)',
    'rgba(245, 158, 11, 0.12)'
  ];
  let particles = [];
  let width = 0, height = 0;
  const PARTICLE_COUNT = 80;
  const MAX_RADIUS = 3.5;
  const pointer = { x: -9999, y: -9999 };
  function resize() {
    const rect = canvas.parentElement.getBoundingClientRect();
    width = Math.floor(rect.width);
    height = Math.floor(rect.height);
    canvas.width = Math.floor(width * DPR);
    canvas.height = Math.floor(height * DPR);
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  class Particle {
    constructor() { this.reset(true); }
    reset(randomPos = false) {
      this.x = randomPos ? Math.random() * width : (Math.random() < 0.5 ? 0 : width);
      this.y = randomPos ? Math.random() * height : Math.random() * height;
      const speed = 0.3 + Math.random() * 0.7;
      const angle = Math.random() * Math.PI * 2;
      this.vx = Math.cos(angle) * speed;
      this.vy = Math.sin(angle) * speed;
      this.r = 1 + Math.random() * MAX_RADIUS;
      this.color = colors[(Math.random() * colors.length) | 0];
    }
    update() {
      const dx = this.x - pointer.x;
      const dy = this.y - pointer.y;
      const dist2 = dx * dx + dy * dy;
      if (dist2 < 12000) {
        const force = Math.max(0, 12000 - dist2) / 12000;
        this.vx += (dx / Math.sqrt(dist2 + 0.001)) * force * 0.4;
        this.vy += (dy / Math.sqrt(dist2 + 0.001)) * force * 0.4;
      }
      this.x += this.vx; this.y += this.vy;
      if (this.x < -10 || this.x > width + 10 || this.y < -10 || this.y > height + 10) this.reset();
      this.vx *= 0.995; this.vy *= 0.995;
    }
    draw() { ctx.beginPath(); ctx.fillStyle = this.color; ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2); ctx.fill(); }
  }
  function initParticles() { particles = []; for (let i = 0; i < PARTICLE_COUNT; i++) particles.push(new Particle()); }
  function drawConnections() {
    const maxDist2 = 120 * 120; ctx.lineWidth = 1;
    for (let i = 0; i < particles.length; i++) for (let j = i + 1; j < particles.length; j++) {
      const a = particles[i], b = particles[j]; const dx = a.x - b.x, dy = a.y - b.y; const d2 = dx * dx + dy * dy;
      if (d2 < maxDist2) { const alpha = 0.08 * (1 - d2 / maxDist2); ctx.strokeStyle = `rgba(15, 23, 42, ${alpha})`; ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke(); }
    }
  }
  function tick() { ctx.clearRect(0, 0, width, height); particles.forEach(p => { p.update(); p.draw(); }); drawConnections(); requestAnimationFrame(tick); }
  resize(); initParticles(); tick();
  window.addEventListener('resize', () => { resize(); initParticles(); });
  canvas.addEventListener('mousemove', (e) => { const rect = canvas.getBoundingClientRect(); pointer.x = e.clientX - rect.left; pointer.y = e.clientY - rect.top; });
  canvas.addEventListener('mouseleave', () => { pointer.x = -9999; pointer.y = -9999; });
});

function showToast(message, type = 'success') {
  const host = document.getElementById('toasts');
  if (!host) return;
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = type === 'success' ? `<i class="fa-solid fa-circle-check"></i> ${message}` : `<i class="fa-solid fa-triangle-exclamation"></i> ${message}`;
  host.appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

function confirmModal(message) {
  return new Promise((resolve) => {
    const modal = document.getElementById('modal');
    if (!modal) { resolve(confirm(message)); return; }
    modal.querySelector('.modal-body').textContent = message;
    modal.hidden = false;
    const cleanup = () => { modal.hidden = true; ok.removeEventListener('click', onOk); cancel.removeEventListener('click', onCancel); };
    const ok = modal.querySelector('[data-modal-confirm]');
    const cancel = modal.querySelector('[data-modal-cancel]');
    function onOk() { cleanup(); resolve(true); }
    function onCancel() { cleanup(); resolve(false); }
    ok.addEventListener('click', onOk);
    cancel.addEventListener('click', onCancel);
  });
}
