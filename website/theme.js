'use strict';
(() => {
  const storageKey = 'bigmouse-guide-theme';
  const systemTheme = window.matchMedia('(prefers-color-scheme: dark)');
  const readPreference = () => {
    try {
      const value = localStorage.getItem(storageKey);
      return value === 'light' || value === 'dark' ? value : null;
    } catch { return null; }
  };
  let preference = readPreference();
  function applyTheme() {
    const theme = preference || (systemTheme.matches ? 'dark' : 'light');
    document.documentElement.dataset.theme = theme;
    document.querySelector('meta[name="theme-color"]').content = theme === 'dark' ? '#0d1523' : '#ffffff';
    document.querySelectorAll('[data-theme-choice]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.themeChoice === theme));
    });
  }
  // Resolve before the stylesheet loads to avoid a flash of the other mode.
  applyTheme();
  document.addEventListener('DOMContentLoaded', () => {
    applyTheme();
    document.querySelectorAll('[data-theme-choice]').forEach(button => {
      button.addEventListener('click', () => {
        preference = button.dataset.themeChoice;
        try { localStorage.setItem(storageKey, preference); } catch { /* Keep this page's choice. */ }
        applyTheme();
      });
    });
  });
  systemTheme.addEventListener('change', () => { if (!preference) applyTheme(); });
  window.addEventListener('storage', event => {
    if (event.key === storageKey || event.key === null) {
      preference = readPreference();
      applyTheme();
    }
  });
})();
