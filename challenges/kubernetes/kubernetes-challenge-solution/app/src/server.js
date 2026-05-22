const http = require('http');
const {
  ensureSchema,
  pingDatabase,
  insertDado,
  listDados,
} = require('./db');

const PORT = Number(process.env.PORT || 3000);
let dbReady = false;

function sendJson(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  return JSON.parse(raw);
}

async function bootstrapDatabase(retries = 30, delayMs = 2000) {
  for (let i = 1; i <= retries; i += 1) {
    try {
      await ensureSchema();
      dbReady = true;
      // eslint-disable-next-line no-console
      console.log('Banco inicializado.');
      return;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.warn(`Tentativa ${i}/${retries} — aguardando MySQL: ${err.message}`);
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error('Nao foi possivel conectar ao MySQL');
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.url === '/healthz' && req.method === 'GET') {
      return sendJson(res, 200, { status: 'ok' });
    }

    if (req.url === '/readyz' && req.method === 'GET') {
      if (!dbReady) {
        return sendJson(res, 503, { status: 'not_ready', database: 'initializing' });
      }
      await pingDatabase();
      return sendJson(res, 200, { status: 'ready' });
    }

    if (req.url === '/status' && req.method === 'GET') {
      await pingDatabase();
      return sendJson(res, 200, { message: 'Conexão OK' });
    }

    if (req.url === '/dados' && req.method === 'GET') {
      const itens = await listDados();
      return sendJson(res, 200, { total: itens.length, itens });
    }

    if (req.url === '/dados' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const created = await insertDado(body);
      return sendJson(res, 201, { message: 'Registro criado', ...created });
    }

    if (req.url === '/' && req.method === 'GET') {
      return sendJson(res, 200, {
        service: 'desafio-api',
        endpoints: ['GET /status', 'POST /dados', 'GET /dados', 'GET /healthz', 'GET /readyz'],
      });
    }

    return sendJson(res, 404, { error: 'not_found' });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error(err);
    return sendJson(res, 500, { error: 'internal_error', detail: err.message });
  }
});

bootstrapDatabase()
  .then(() => {
    server.listen(PORT, () => {
      // eslint-disable-next-line no-console
      console.log(`API em :${PORT}`);
    });
  })
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  });
