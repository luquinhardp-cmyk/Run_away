/* Stream payloads, including CDN double compression, without full-size copies. */
(() => {
  const fetchOriginal = window.fetch.bind(window);
  async function normalize(body) {
    for (let layer = 0; layer < 2; layer++) {
      const reader = body.getReader();
      const prefix = [];
      let size = 0;
      while (size < 2) {
        const chunk = await reader.read();
        if (chunk.done) break;
        prefix.push(chunk.value);
        size += chunk.value.length;
      }
      const first = [];
      for (const chunk of prefix) {
        for (let i = 0; i < chunk.length && first.length < 2; i++) first.push(chunk[i]);
        if (first.length === 2) break;
      }
      body = new ReadableStream({
        async pull(controller) {
          if (prefix.length) { controller.enqueue(prefix.shift()); return; }
          try {
            const chunk = await reader.read();
            if (chunk.done) controller.close(); else controller.enqueue(chunk.value);
          } catch (error) { controller.error(error); }
        },
        cancel(reason) { return reader.cancel(reason); }
      });
      if (first[0] !== 0x1f || first[1] !== 0x8b) break;
      if (!('DecompressionStream' in window)) {
        await body.cancel();
        throw new Error('Este navegador não suporta a descompressão do jogo. Atualize o navegador ou baixe o APK Android.');
      }
      body = body.pipeThrough(new DecompressionStream('gzip'));
    }
    return body;
  }
  window.fetch = async function(input, options) {
    const url = new URL(typeof input === 'string' ? input : input.url || String(input), location.href);
    const wasm = url.pathname.endsWith('/index.wasm');
    const pack = url.pathname.endsWith('/index.pck');
    let response;
    if (pack && Array.isArray(window.ECOS_PACK_PARTS) && window.ECOS_PACK_PARTS.length) {
      const names = window.ECOS_PACK_PARTS.slice();
      let reader;
      const abort = new AbortController();
      const callerSignal = options?.signal || (typeof input === 'object' ? input.signal : undefined);
      const cancel = () => abort.abort(callerSignal?.reason);
      if (callerSignal?.aborted) cancel();
      else callerSignal?.addEventListener('abort', cancel, {once: true});
      const cleanup = () => callerSignal?.removeEventListener('abort', cancel);
      response = new Response(new ReadableStream({
        async pull(controller) {
          try {
            while (true) {
              if (!reader) {
                if (!names.length) { cleanup(); controller.close(); return; }
                const part = await fetchOriginal(new URL(names.shift(), url).href, {...options, signal: abort.signal});
                if (!part.ok) throw new Error('Falha ao baixar uma parte do jogo: ' + part.status);
                reader = part.body.getReader();
              }
              const chunk = await reader.read();
              if (chunk.done) { reader.releaseLock(); reader = null; continue; }
              controller.enqueue(chunk.value);
              return;
            }
          } catch (error) { cleanup(); abort.abort(); controller.error(error); }
        },
        async cancel(reason) { cleanup(); abort.abort(reason); if (reader) await reader.cancel(reason); }
      }), {status: 200});
    } else {
      response = await fetchOriginal(input, options);
    }
    if ((!wasm && !pack) || !response.ok || !response.body) return response;
    const headers = new Headers(response.headers);
    headers.delete('Content-Encoding');
    headers.delete('Content-Length');
    headers.set('Content-Type', wasm ? 'application/wasm' : 'application/octet-stream');
    return new Response(await normalize(response.body), {status: response.status, statusText: response.statusText, headers});
  };
})();
