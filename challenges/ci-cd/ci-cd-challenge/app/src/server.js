const http = require('http');

const PORT = Number(process.env.PORT || 3000);
const APP_ENV = process.env.APP_ENV || 'local';

function sendJson(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

function createServer() {
  return http.createServer((req, res) => {
    if (req.url === '/health' && req.method === 'GET') {
      return sendJson(res, 200, {
        status: 'ok',
        environment: process.env.APP_ENV || APP_ENV,
        timestamp: new Date().toISOString(),
      });
    }

    if (req.url === '/' && req.method === 'GET') {
      return sendJson(res, 200, {
        message: 'CI/CD Challenge API',
        environment: process.env.APP_ENV || APP_ENV,
      });
    }

    sendJson(res, 404, { error: 'not_found' });
  });
}

if (require.main === module) {
  createServer().listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`API listening on :${PORT} (${APP_ENV})`);
  });
}

module.exports = { createServer, PORT, APP_ENV };
