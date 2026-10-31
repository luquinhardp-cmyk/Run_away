# Hospedagem

Entrega local: `builds/web-audit/release/`. Exportação de diagnóstico separada: `builds/web-audit/site/`; esta última abre o benchmark, não deve substituir o jogo público.

Mantidos Web sem threads, pacote gzip dividido em partes abaixo de 25 MiB e carregador que também aceita gzip já removido pelo CDN ou dupla compressão. `hosting/_headers` preserva MIME, no-cache e política microphone=self. Sem threads, não se adicionou isolamento COOP/COEP desnecessário.

Nenhum deployment foi feito. Os endereços de publicação futura permanecem `https://run-away-ecos.pages.dev/`, `/play/` e `/baixar-apk`. O APK do build local aponta para a versão pública existente; esta auditoria não gera uma atualização Android nova.

O teste local não reproduz todos os comportamentos do CDN. Antes de publicar, validar HTTPS, cabeçalhos, versão, cache e redirecionamento no endereço canônico com autorização do usuário. `hosting/prepare.py` deve receber explicitamente `--apk-url` da versão desejada; seu padrão histórico não deve ser usado numa publicação nova.

Inspeção somente leitura da produção via Node fetch: raiz e /play/ responderam 200; /baixar-apk respondeu 302 para `v0.9.0-creature-study/ecos-android.apk`; WASM respondeu 200 com application/wasm e gzip. Evidência em `production-headers-node.json`. A mesma tentativa por urllib recebeu 403 do caminho de acesso utilizado; o arquivo correspondente registra essa limitação, não uma indisponibilidade geral do site.
