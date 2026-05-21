const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { createServer } = require('./server');

function request(server, path) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      { host: '127.0.0.1', port: server.address().port, path, method: 'GET' },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
      },
    );
    req.on('error', reject);
    req.end();
  });
}

describe('API', () => {
  /** @type {import('http').Server} */
  let server;

  before(() => {
    process.env.APP_ENV = 'test';
    server = createServer();
    server.listen(0);
  });

  after(() => {
    server.close();
  });

  it('GET / retorna mensagem', async () => {
    const res = await request(server, '/');
    assert.equal(res.status, 200);
    assert.equal(res.body.environment, 'test');
  });

  it('GET /health retorna ok', async () => {
    const res = await request(server, '/health');
    assert.equal(res.status, 200);
    assert.equal(res.body.status, 'ok');
  });
});
