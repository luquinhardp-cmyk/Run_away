/* Normalize the two compressed game payloads, including CDN double compression. */
(() => {
  const fetchOriginal = window.fetch.bind(window);
  window.fetch = async function(input, options) {
    const url = new URL(typeof input === 'string' ? input : input.url || String(input), location.href);
    const wasm = url.pathname.endsWith('/index.wasm');
    const pack = url.pathname.endsWith('/index.pck');
    let response;
    if (pack && Array.isArray(window.ECOS_PACK_PARTS) && window.ECOS_PACK_PARTS.length) {
      const parts = await Promise.all(window.ECOS_PACK_PARTS.map(async name => {
        const part = await fetchOriginal(new URL(name, url).href, options);
        if (!part.ok) throw new Error('Falha ao baixar uma parte do jogo: ' + part.status);
        return part.arrayBuffer();
      }));
      response = new Response(new Blob(parts).stream(), {status: 200});
    } else {
      response = await fetchOriginal(input, options);
    }
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
