const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const zlib = require('node:zlib');
const source = fs.readFileSync('hosting/wasm-loader.js', 'utf8');
const raw = Buffer.from('GDPC-test-pack-content');
const compressed = zlib.gzipSync(raw);
function environment(parts, fetcher) {
  const window = {fetch: fetcher, DecompressionStream, ECOS_PACK_PARTS: parts};
  vm.runInNewContext(source, {window, location: {href:'https://example.com/play/'}, URL, Response, Headers, Blob, Uint8Array, DecompressionStream, Error});
  return window;
}
(async () => {
  for (const depth of [0,1,2]) {
    let data = raw;
    for (let i=0;i<depth;i++) data=zlib.gzipSync(data);
    const w=environment(null,async()=>new Response(data));
    const r=await w.fetch('index.pck');
    assert.deepEqual(Buffer.from(await r.arrayBuffer()),raw);
    assert.equal(Number(r.headers.get('Content-Length')),raw.length);
  }
  const requests=[];
  const split=environment(['index.pck.part0','index.pck.part1'],async url=>{
    requests.push(url);
    return new Response(url.endsWith('part0')?compressed.subarray(0,9):compressed.subarray(9));
  });
  assert.deepEqual(Buffer.from(await (await split.fetch('index.pck')).arrayBuffer()),raw);
  assert.equal(requests.length,2);
  assert.ok(requests.every(url=>url.startsWith('https://example.com/play/index.pck.part')));
  const failed=environment(['missing'],async()=>new Response('',{status:404}));
  await assert.rejects(()=>failed.fetch('index.pck'),/404/);
  const other=environment(null,async()=>new Response('unchanged',{status:201}));
  const response=await other.fetch('other.json');
  assert.equal(response.status,201);
  assert.equal(await response.text(),'unchanged');
  console.log('HOSTING PASS: raw/single/double gzip, split reconstruction, URLs, failure and passthrough');
})().catch(error=>{console.error(error);process.exit(1)});
