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

  const canvas = document.getElementById('bg-particles');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  const DPR = Math.min(window.devicePixelRatio || 1, 2);
  const colors = [
    'rgba(37, 99, 235, 0.12)', // blue-600
    'rgba(34, 197, 94, 0.12)', // green-500
    'rgba(99, 102, 241, 0.12)', // indigo-500
    'rgba(245, 158, 11, 0.12)'  // amber-500
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
    constructor() {
      this.reset(true);
    }
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
      // gentle repulsion from pointer
      const dx = this.x - pointer.x;
      const dy = this.y - pointer.y;
      const dist2 = dx * dx + dy * dy;
      if (dist2 < 12000) {
        const force = Math.max(0, 12000 - dist2) / 12000;
        this.vx += (dx / Math.sqrt(dist2 + 0.001)) * force * 0.4;
        this.vy += (dy / Math.sqrt(dist2 + 0.001)) * force * 0.4;
      }

      this.x += this.vx;
      this.y += this.vy;

      // soft bounds; wrap around
      if (this.x < -10 || this.x > width + 10 || this.y < -10 || this.y > height + 10) {
        this.reset();
      }

      // slight velocity damping
      this.vx *= 0.995;
      this.vy *= 0.995;
    }
    draw() {
      ctx.beginPath();
      ctx.fillStyle = this.color;
      ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function initParticles() {
    particles = [];
    for (let i = 0; i < PARTICLE_COUNT; i++) {
      particles.push(new Particle());
    }
  }

  function drawConnections() {
    // optional subtle lines between close particles
    const maxDist2 = 120 * 120;
    ctx.lineWidth = 1;
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const a = particles[i], b = particles[j];
        const dx = a.x - b.x, dy = a.y - b.y;
        const d2 = dx * dx + dy * dy;
        if (d2 < maxDist2) {
          const alpha = 0.08 * (1 - d2 / maxDist2);
          ctx.strokeStyle = `rgba(15, 23, 42, ${alpha})`;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
      }
    }
  }

  function tick() {
    ctx.clearRect(0, 0, width, height);
    particles.forEach(p => { p.update(); p.draw(); });
    drawConnections();
    requestAnimationFrame(tick);
  }

  resize();
  initParticles();
  tick();

  window.addEventListener('resize', () => {
    resize();
    initParticles();
  });
  canvas.addEventListener('mousemove', (e) => {
    const rect = canvas.getBoundingClientRect();
    pointer.x = e.clientX - rect.left;
    pointer.y = e.clientY - rect.top;
  });
  canvas.addEventListener('mouseleave', () => {
    pointer.x = -9999; pointer.y = -9999;
  });
});
