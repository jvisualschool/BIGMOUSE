'use strict';
(() => {
  const $ = selector => document.querySelector(selector);
  let language = 'en';
  try {
    const stored = localStorage.getItem('bigmouse-guide-language');
    language = ['ko','en'].includes(stored) ? stored : (new Intl.Locale(navigator.language).region === 'KR' ? 'ko' : 'en');
  } catch { language = /[-_]KR\b/i.test(navigator.language || '') ? 'ko' : 'en'; }
  const screenshotPath = filename => 'assets/screenshots/' + (language === 'en' ? 'en/' + filename.replace(/\.png$/, '.jpg') : filename);
  function setScreenshot(image, filename) {
    image.src = screenshotPath(filename);
    image.width = language === 'en' ? 1120 : 1000;
    image.height = 1644;
  }
  const el = (tag, className, text) => {
    const node = document.createElement(tag);
    if(className) node.className = className;
    if(text !== undefined) node.textContent = text;
    return node;
  };
  const list = (items, className) => {
    const node = el('ol',className);
    items.forEach(text => node.append(el('li','',text)));
    return node;
  };
  const dialog = $('#image-dialog');
  let imageTrigger = null;
  function openImage(src, caption, trigger) {
    imageTrigger = trigger;
    $('#expanded-image').src = src;
    $('#expanded-image').alt = caption;
    $('#image-caption').textContent = caption;
    dialog.showModal();
    document.body.classList.add('modal-open');
    $('#close-image').focus();
  }
  $('#close-image').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if(event.target === dialog) {
      const r=dialog.getBoundingClientRect();
      if(event.clientX<r.left || event.clientX>r.right || event.clientY<r.top || event.clientY>r.bottom) dialog.close();
    }
  });
  dialog.addEventListener('close', () => { document.body.classList.remove('modal-open'); imageTrigger?.focus(); });
  function render() {
    const t = guideContent[language];
    document.documentElement.lang = language;
    document.title = t.pageTitle;
    document.querySelectorAll('[data-t]').forEach(n => n.textContent = t[n.dataset.t]);
    document.querySelectorAll('[data-alt]').forEach(n => n.alt = t[n.dataset.alt]);
    document.querySelectorAll('[data-aria]').forEach(n => n.setAttribute('aria-label',t[n.dataset.aria]));
    document.querySelectorAll('[data-lang]').forEach(n => n.setAttribute('aria-pressed',String(n.dataset.lang===language)));
    const steps = $('#start-steps'); steps.replaceChildren();
    t.start.forEach(([title,description]) => {
      const li=el('li'); li.append(el('h3','',title),el('p','',description)); steps.append(li);
    });
    const guides=$('#feature-guides'); guides.replaceChildren();
    t.features.forEach(f => {
      const article=el('article','feature'); article.id=f.id;
      const text=el('div','feature-content');
      text.append(el('p','feature-number',f.number),el('h3','',f.title),el('p','feature-summary',f.summary),list(f.steps,'numbered'),el('p','feature-tip',f.tip));
      const figure=el('figure');
      const button=el('button','screenshot-button'); button.type='button'; button.setAttribute('aria-label',t.expand+': '+f.title);
      const image=el('img'); setScreenshot(image,f.image); image.alt=f.alt; image.loading='lazy';
      button.append(image); button.addEventListener('click',()=>openImage(image.src,f.caption,button));
      figure.append(button,el('figcaption','',f.caption)); article.append(text,figure); guides.append(article);
    });
    const permissions=$('#permission-guides'); permissions.replaceChildren();
    t.permissions.forEach(p => {
      const card=el('article','permission-card'); card.append(el('h3','',p.title),el('p','permission-for',p.for),el('p','path',p.path),list(p.steps,'numbered')); permissions.append(card);
    });
    const repairs=$('#repair-steps'); repairs.replaceChildren(); t.repair.forEach(text=>repairs.append(el('li','',text)));
    const checks=$('#presentation-checks'); checks.replaceChildren(); t.checks.forEach(text=>checks.append(el('li','',text)));
    const faqs=$('#faq-list'); faqs.replaceChildren();
    t.faq.forEach(([q,a])=>{const item=el('details');item.append(el('summary','',q),el('p','',a));faqs.append(item);});
    document.querySelectorAll('[data-screenshot]').forEach(button => {
      const image = button.querySelector('img');
      setScreenshot(image, button.dataset.screenshot);
      button.onclick = () => openImage(image.src, t[button.dataset.caption], button);
    });
    document.querySelectorAll('[data-demo]').forEach(button => {
      button.onclick = () => openImage(button.querySelector('img').src,t[button.dataset.caption],button);
    });
    document.querySelector('.footer>a:last-child').href=language==='ko'?'README.md':'README.en.md';
  }
  document.querySelectorAll('[data-lang]').forEach(button=>button.addEventListener('click',()=>{
    language=button.dataset.lang; try{localStorage.setItem('bigmouse-guide-language',language);}catch{}
    render();
  }));
  render();
})();
