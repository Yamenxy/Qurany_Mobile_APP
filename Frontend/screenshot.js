const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  try {
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const page = await browser.newPage();
    
    page.on('console', msg => console.log('BROWSER_CONSOLE:', msg.text()));
    page.on('pageerror', err => console.log('BROWSER_ERROR_PAGE:', err.toString()));
    
    await page.setViewport({ width: 390, height: 844 });
    
    console.log('Navigating to http://localhost:8081...');
    await page.goto('http://localhost:8081', { waitUntil: 'networkidle0', timeout: 60000 });
    
    console.log('Page loaded. Waiting 2s for animations...');
    await new Promise(r => setTimeout(r, 2000));

    const outPath = path.join('C:\\Users\\Abdulrahman Hossam\\.gemini\\antigravity-ide\\brain\\73b08cf4-e509-417d-b206-02955fc7ad4c', 'app_screenshot.png');
    await page.screenshot({ path: outPath });
    
    console.log('Screenshot saved to', outPath);
    await browser.close();
  } catch (err) {
    console.error('Script Error:', err);
  }
})();
