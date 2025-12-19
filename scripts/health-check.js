#!/usr/bin/env node

const http = require('http');

const host = process.env.WP_HOME || 'http://localhost:8080';
const urls = [
  '/',
  '/category/gay-car-reviews/',
  '/about/'
];

function checkUrl(path) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, host);
    const req = http.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`${url.href} returned ${res.statusCode}`));
        return;
      }
      res.resume();
      resolve();
    });
    req.on('error', reject);
  });
}

(async () => {
  try {
    for (const path of urls) {
      // eslint-disable-next-line no-console
      console.log(`Checking ${path}...`);
      await checkUrl(path);
    }
    // eslint-disable-next-line no-console
    console.log('Health checks passed.');
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('Health check failed:', err.message);
    process.exit(1);
  }
})();


