/* Normalize the two compressed game payloads, including CDN double compression. */
(() => {
  const fetchOriginal = window.fetch.bind(window);
  window.fetch = async function(input, options) {
    const response = await fetchOriginal(input, options);
    const url = new URL(typeof input === 'string' ? input : input.url || String(input), location.href);
    const wasm = url.pathname.endsWith('/index.wasm');
    const pack = url.pathname.endsWith('/index.pck');
    if ((!wasm && !pack) || !response.ok) return response;
    let data = await response.arrayBuffer();
    let bytes = new Uint8Array(data);
    for (let layer = 0; layer < 2 && bytes[0] === 0x1f && bytes[1] === 0x8b; layer++) {
      if (!('DecompressionStream' in window)) {
        throw new Error('Este navegador não suporta a descompressão do jogo. Atualize o navegador ou baixe o APK Android.');
      }
      const stream = new Blob([data]).stream().pipeThrough(new DecompressionStream('gzip'));
      data = await new Response(stream).arrayBuffer();
      bytes = new Uint8Array(data);
    }
    const headers = new Headers(response.headers);
    headers.delete('Content-Encoding');
    headers.set('Content-Type', wasm ? 'application/wasm' : 'application/octet-stream');
    headers.set('Content-Length', String(data.byteLength));
    return new Response(data, { status: response.status, statusText: response.statusText, headers });
  };
})();
