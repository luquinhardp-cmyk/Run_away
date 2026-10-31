# Entrega ECOS 0.8

Branch `feature/detailed-geometry-models`. Runtime gráfico/captura: `35eb9b1`; entrega web com download dividido: `d85e109`. Prévia separada da produção 0.3.

- [Jogar na Web](https://feature-detailed-geometry-mo.run-away-ecos.pages.dev/)
- [Build web imutável](https://6871a26b.run-away-ecos.pages.dev/)
- [Baixar/atualizar APK ARM64](https://github.com/luquinhardp-cmyk/Run_away/releases/download/v0.8.0-geometry/ecos-android.apk)
- [Release de testes](https://github.com/luquinhardp-cmyk/Run_away/releases/tag/v0.8.0-geometry)

## Concluído

Biblioteca de 37 modelos originais Blender, com dois exports/LODs por modelo; itens próximos, gerador, painel, portas, móveis e arquitetura detalhados. Floresta/terreno refinados preservando rotas e física. [Relatório de geometria](GEOMETRIA_E_MODELAGEM_3D.md).

Mipmap/filtragem, MSAA, três perfis e opções independentes de FPS, escala, sombras e vegetação; resolução adaptativa opcional. Redução de consultas de teto e projeção navegável redundantes. Mais qualidade também aumentou o custo e a memória; não há promessa de melhora geral de FPS. [Comparativo real](COMPARATIVO_DESEMPENHO.md).

Captura com aproximação frontal do rosto, FOV 42°, luz local e som mais forte, preservando volumes e acessibilidade. APK com pacote e certificado iguais aos APKs 0.3/0.7 e versionCode 8. [Atualização Android e captura](ATUALIZACAO_ANDROID_E_CAPTURA.md).

APK: 54.269.522 bytes; SHA-256 `210a8d51da7f2b9c1519ba6f797afd3b43123c45e51546c540a0fad5826fac12`. Assinatura de depuração existente preservada. Para atualizar, abrir o novo APK mantendo a instalação anterior e confirmar **Atualizar**; não é atualização silenciosa. Atalhos de navegador/PWAs são independentes de um APK.

## Verificação

522 verificações automatizadas: 229 geometria, 80 gerais, 41 expansão, 29 horror/captura, 76 ambiente noturno, 47 física e 20 gráficos; zero falhas. O runner de expansão resolve os objetivos e conclui a fuga. O loader web também passou nos testes de gzip simples/duplo, recomposição do pacote em partes, caminhos, falha de download e passthrough.

Exportações Web/Android concluídas. Verificador de APK confirmou pacote, assinatura válida, certificado idêntico e código crescente contra as versões 0.3 e 0.7. Evidências e screenshots em `review/performance/`. O pacote web gzip de 29.297.661 bytes é servido em duas partes abaixo do limite individual do Cloudflare, sem retirar modelos ou texturas.

Validação na URL publicada passou em Chromium/WebGL com backend D3D11: download das duas partes, inicialização, consentimento sem microfone, gameplay, pausa, cadastro pela interface, criação do documento protegido no Firestore e importação do checkpoint convidado com 12 objetos físicos e gaveta. Zero erros de execução; o 404 inicial de documento ainda inexistente é esperado no cadastro. Conta temporária excluída pelo teste e um documento temporário removido na limpeza; auditoria da janela de testes não encontrou contas de tentativas interrompidas. Screenshots `review/performance/web_gameplay.png` e `web_account.png`. A primeira tentativa com SwiftShader foi interrompida por lentidão do ambiente; isso não certifica desempenho gráfico da Web em celulares.

Metadados remotos confirmaram prévia 0.8.0/commit `d85e109` e APK HTTP 200/54.269.522 bytes. A URL de produção continua em 0.3.0. Não houve alteração de regras ou publicação de backend no Firebase.

Limites: medições gráficas em Intel UHD/Compatibility, não Android. Sem aparelho conectado para instalar por cima da versão anterior e conferir dados preservados, multitoque, microfone real, latência acústica, aquecimento, bateria ou sessão prolongada. A opção alta apresentou picos severos no desktop; nenhum alvo de 30/60 FPS foi certificado para celulares. Login, schema/regras e serviços Firebase existentes foram preservados.
