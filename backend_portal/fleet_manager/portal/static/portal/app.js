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
    // Load default section on first visit
    initial.click();
  }
});
