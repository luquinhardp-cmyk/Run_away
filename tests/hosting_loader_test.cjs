const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const zlib = require('node:zlib');
const source = fs.readFileSync('hosting/wasm-loader.js', 'utf8');
const raw = Buffer.from('GDPC-test-pack-content');
const compressed = zlib.gzipSync(raw);
function environment(parts, fetcher) {
  const window = {fetch: fetcher, DecompressionStream, ECOS_PACK_PARTS: parts};
  vm.runInNewContext(source, {window, location: {href:'https://example.com/play/'}, URL, Response, Headers, Blob, Uint8Array, DecompressionStream, ReadableStream, AbortController, Error});
  return window;
}
(async () => {
  for (const depth of [0,1,2]) {
    let data = raw;
    for (let i=0;i<depth;i++) data=zlib.gzipSync(data);
    const w=environment(null,async()=>new Response(data));
    const r=await w.fetch('index.pck');
    assert.deepEqual(Buffer.from(await r.arrayBuffer()),raw);
    assert.equal(r.headers.get('Content-Length'),null);
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
  await assert.rejects(async()=> (await failed.fetch('index.pck')).arrayBuffer(),/404/);
  const other=environment(null,async()=>new Response('unchanged',{status:201}));
  const response=await other.fetch('other.json');
  assert.equal(response.status,201);
  assert.equal(await response.text(),'unchanged');
  // Magic bytes can straddle network chunks. Also exercise actual streaming WASM compilation.
  const wasm=Buffer.from([0,97,115,109,1,0,0,0]);
  const encoded=zlib.gzipSync(wasm);
  const fragmented=environment(null,async()=>new Response(new ReadableStream({
    start(controller){for(const byte of encoded)controller.enqueue(Uint8Array.of(byte));controller.close()}
  })));
  await WebAssembly.compileStreaming(await fragmented.fetch('index.wasm'));
  const truncated=environment(null,async()=>new Response(compressed.subarray(0,10)));
  await assert.rejects(async()=> (await truncated.fetch('index.pck')).arrayBuffer());
  const lateFailure=environment(['ok','missing'],async url=>new Response(url.endsWith('ok')?raw:'', {status:url.endsWith('ok')?200:404}));
  await assert.rejects(async()=> (await lateFailure.fetch('index.pck')).arrayBuffer(), /404/);
  let downloads=0;
  let signal;
  const sequential=environment(['first','second','third'],async (_url,options)=>{
    downloads++; signal=options.signal;
    let produced=0;
    return new Response(new ReadableStream({pull(c){if(produced++<20)c.enqueue(new Uint8Array(65536));else c.close()}}));
  });
  const streamed=await sequential.fetch('index.pck');
  assert.equal(downloads,1,'later parts are not buffered eagerly');
  await streamed.body.cancel('left page');
  assert.equal(signal.aborted,true,'cancellation aborts the current network part');
  assert.equal(downloads,1);
  console.log('HOSTING PASS: raw/single/double gzip, split reconstruction, URLs, failure and passthrough');
  console.log('STREAM PASS: fragmented headers, streaming WASM, truncated gzip, later-part failure, backpressure and cancellation');
})().catch(error=>{console.error(error);process.exit(1)});
