const mysql = require('mysql2/promise');

let pool;

function getConfig() {
  return {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'app_user',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_DATABASE || 'desafio_db',
    waitForConnections: true,
    connectionLimit: 8,
  };
}

async function getPool() {
  if (!pool) {
    pool = mysql.createPool(getConfig());
  }
  return pool;
}

async function ensureSchema() {
  const p = await getPool();
  await p.query(`
    CREATE TABLE IF NOT EXISTS dados (
      id INT AUTO_INCREMENT PRIMARY KEY,
      conteudo JSON NOT NULL,
      criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

async function pingDatabase() {
  const p = await getPool();
  await p.query('SELECT 1');
}

async function insertDado(conteudo) {
  const p = await getPool();
  const [result] = await p.query('INSERT INTO dados (conteudo) VALUES (?)', [
    JSON.stringify(conteudo),
  ]);
  return { id: result.insertId };
}

async function listDados() {
  const p = await getPool();
  const [rows] = await p.query(
    'SELECT id, conteudo, criado_em FROM dados ORDER BY id DESC LIMIT 100',
  );
  return rows.map((row) => ({
    id: row.id,
    conteudo: typeof row.conteudo === 'string' ? JSON.parse(row.conteudo) : row.conteudo,
    criado_em: row.criado_em,
  }));
}

module.exports = {
  getPool,
  ensureSchema,
  pingDatabase,
  insertDado,
  listDados,
};
