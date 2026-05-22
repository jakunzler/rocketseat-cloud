const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

describe('config', () => {
  it('usa porta padrao 3000', () => {
    const port = Number(process.env.PORT || 3000);
    assert.equal(port, 3000);
  });
});
