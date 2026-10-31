"""Render recorded desktop measurements without treating targets as guarantees."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / "docs/review/performance"
before = json.loads((p / "before_q1.json").read_text())["results"]
after = json.loads((p / "after_q1.json").read_text())["results"]
rows = ["| Cenario | FPS antes | FPS depois | p95 antes (ms) | p95 depois (ms) |",
        "|---|---:|---:|---:|---:|"]
for a, b in zip(before, after):
    rows.append(f"| {a['scenario']} | {a['fps']:.1f} | {b['fps']:.1f} | {a['p95_frame_ms']:.2f} | {b['p95_frame_ms']:.2f} |")
text = """# Comparativo de desempenho

Ensaio desktop Intel UHD, Godot 4.7.2 Compatibility, janela 1280x720, VSync desligado e FPS sem limite exclusivamente no benchmark. Antes: geometria b62623d, medio 85%, sem MSAA/sombra da lanterna. Depois: medio 100%, MSAA 2x, sombra da lanterna e mipmaps. Portanto a tabela compara configuracoes visuais diferentes e nao isola uma otimizacao. Mais qualidade custou desempenho; nao houve ganho geral de FPS.

""" + "\n".join(rows)
text += f"""

Texturas no cenario room: {before[0]['texture_memory_bytes']/1048576:.1f} para {after[0]['texture_memory_bytes']/1048576:.1f} MiB. A memoria adicional dos mipmaps e o custo de sombras/AA devem entrar no orcamento do dispositivo. Dados brutos incluem GPU medida, tempo fisico, IA, memoria, consultas e frames maximos; CPU e GPU nao devem ser somados como tempos sequenciais.

Na floresta, consultas de teto cairam de {before[2]['roof_rays_per_s']:.1f} para {after[2]['roof_rays_per_s']:.1f}/s; durante voo, de {before[4]['roof_rays_per_s']:.1f} para {after[4]['roof_rays_per_s']:.1f}/s. Isso demonstra a reducao de consultas, sem prometer ganho de FPS proporcional.

Baixo e alto foram medidos separadamente, mesmos dez cenarios, com exploracao de 8 s; medio e referencia usam 60 s. Os arquivos after_q0/after_q1/after_q2.json sao a evidencia. Nao sao testes termicos prolongados. Alto inclui picos severos de frame em quedas/compilacao inicial e nao sustenta 60 FPS em todas as vistas deste computador. Nao ocultar esses picos por medias globais.

O ensaio sharpness.json compara 85/100/170% com a mesma camera e MSAA 2x. Dobrar a escala linear de .85 para 1.7 quadruplica pixels internos e reduz FPS; nao foi adotado como padrao. Imagens sharpness_*.png permitem revisao visual. A captura foi refinada visualmente depois da primeira medicao; capture_closeup.png e os testes de horror verificam o enquadramento final.

Microfone: RMS sintetico de 2048 amostras, sem entrada fisica. Android: nenhum aparelho conectado, sem certificacao de FPS, calor, bateria, latencia, toque ou atualizacao instalada. O benchmark pode ser repetido com --quality 0/1/2 --steady 60 --uncapped; variabilidade, carregamento inicial e outras cargas do sistema afetam resultados.
"""
(root / "docs/COMPARATIVO_DESEMPENHO.md").write_text(text, encoding="utf-8")
print("Wrote measured comparison")
