# Auditoria visual antes das alterações

Base `c0f7e6f`, Godot 4.7.2 stable, branch `feature/horror-visual-creature-jumpscares`. Referência executada: 69 verificações passaram, zero falhas. Foram examinadas as cenas finas existentes, scripts de fase/arte/player/HUD/IA, rig e gerador Blender, materiais PBR, áudio, eventos, configurações e contrato de checkpoint/Firebase.

- Funcionais e reutilizados: FPS/touch, câmera, perseguição/visão/audição, armários, objetivos, rádio/alarme, arremessáveis, navegação, saves v1/v2 e backend, menus, perfis gráficos, microfone local com consentimento e suspensão.
- Sinalização parcial: todos os nomes de salas/rotas são criados por `facility._label` como Label3D sem suporte. Há textos de dupla face que podem aparecer espelhados pelo verso. HUD contextual é necessário e será preservado.
- Salas parciais: `facility_art.gd` já tem prateleiras, cama, prensa, cabos e tanques. Há espaço para narrativa e identidade própria nas paredes/bordas, preservando as pistas e corredores de navegação.
- Criatura parcial: GLBs funcionais com 29 ossos, 12 clipes, UV/PBR e LOD, mas anatomia segmentada e cabeça pouco diferenciada. Blender 4.5.15 LTS está disponível; será criado outro asset versionado, mantendo o anterior no histórico/arquivos.
- Sons parciais: samples originais, 3D e limite de vozes; não há biblioteca por comportamento com variações e silêncio intencional.
- Captura parcial: ataque válido e cancelável, uma animação genérica, câmera voltada à cabeça, derrota após 0,65 s. Faltam seleção contextual, sequência exclusiva e controles bloqueados só após confirmação.
- Terror parcial: eventos de impacto, cano e apagão persistentes; faltam diretor com tensão/alívio, histórico, cooldown global e biblioteca contextual. Não criar uma segunda criatura falsa.
- Limites preservados: sem dispositivo Android conectado, sem aprovação de FPS/temperatura/bateria ou microfone físico. Materiais, batching e modelos baixos existentes serão reaproveitados. Não haverá publicação em produção durante a implementação.
