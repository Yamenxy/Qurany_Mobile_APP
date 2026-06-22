const puppeteer = require('puppeteer');

(async () => {
  try {
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const page = await browser.newPage();
    
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log('BROWSER_ERROR_CONSOLE:', msg.text());
      } else {
        console.log('BROWSER_CONSOLE:', msg.text());
      }
    });
    
    page.on('pageerror', err => console.log('BROWSER_ERROR_PAGE:', err.toString()));
    
    console.log('Navigating to http://localhost:8081...');
    await page.goto('http://localhost:8081', { waitUntil: 'networkidle0', timeout: 30000 });
    
    console.log('Page loaded. Wait 5s for any async errors...');
    await new Promise(r => setTimeout(r, 5000));
    
    await browser.close();
    console.log('Done.');
  } catch (err) {
    console.error('Script Error:', err);
  }
})();
