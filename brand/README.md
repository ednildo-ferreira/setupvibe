# Marca SetupVibe

O SetupVibe prepara ambientes locais para desenvolvimento. Sua identidade
combina o petróleo e o turquesa da Promovaweb com azul-ciano, variação ligada a
terminal, infraestrutura e configuração.

## Conceito visual

O símbolo preserva o **notebook com terminal de código**. A tela representa o
ambiente configurável; os sinais de código representam automação; a base azul
representa o ambiente pronto para uso.

## Arquivos oficiais

| Arquivo | Uso |
| --- | --- |
| `logo/icon.svg` | ícone principal com placa petróleo |
| `logo/icon-light.svg` | ícone transparente sobre fundo claro |
| `logo/icon-dark.svg` | ícone transparente sobre fundo escuro |
| `logo/logo-light.svg` | assinatura horizontal sobre fundo claro |
| `logo/logo-dark.svg` | assinatura horizontal sobre fundo escuro |
| `logo/logotype.svg` | alias de compatibilidade da assinatura clara |
| `logo/icon.png` | fallback raster de 512 × 512 px |

Preserve 12,5% de área livre ao redor do ativo. O tamanho mínimo é 28 px para
o ícone e 150 px para a assinatura horizontal.

## Sistema digital

- `colors/palette.json`: fonte editável da paleta;
- `tokens.json`: tokens agnósticos;
- `global.css`: webfontes, variáveis CSS e troca de tema;
- `tailwind-theme.js`: extensão para Tailwind CSS;
- `accessibility.md`: relatório de contraste;
- `typography/README.md`: hierarquia tipográfica.

## Regras para agentes

1. Use azul-ciano para infraestrutura, comandos e estados de preparação.
2. Use tokens semânticos e a variante correta para light ou dark mode.
3. Não simplifique o notebook removendo tela, código ou base.
4. Não aplique filtros, gradientes, sombras, rotações ou deformações.
5. Preserve a linguagem direta e operacional descrita em `voice/voice.md`.
