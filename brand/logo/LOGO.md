# Logo oficial do SetupVibe

Este documento governa o ícone e o logotipo do SetupVibe. A geometria do
símbolo vive em [`icon.svg`](icon.svg), enquanto [`icon.png`](icon.png) é o
fallback raster original. A assinatura horizontal está em
[`logotype.svg`](logotype.svg).

## Conceito

O símbolo combina uma janela de terminal com a base de um notebook:

1. **A tela retangular** representa o ambiente onde comandos e ferramentas são
   configurados.
2. **O símbolo de código** representa scripts públicos e trabalho técnico
   verificável.
3. **A base do notebook** conecta a automação à máquina real que será alterada.
4. **O espaço entre tela e base** preserva a leitura do dispositivo em tamanhos
   reduzidos.

O desenho comunica preparação de ambiente sem representar uma plataforma
hospedada ou um sistema operacional específico.

## Arquivos canônicos

| Arquivo | Papel | Quando usar |
| --- | --- | --- |
| [`icon.svg`](icon.svg) | Símbolo vetorial mestre, 512 × 512 | Interface, README, documentação, impressão e avatar |
| [`icon.png`](icon.png) | Fallback RGBA, 512 × 512 | Integrações sem suporte a SVG |
| [`logotype.svg`](logotype.svg) | Assinatura horizontal com símbolo e nome | Cabeçalhos e materiais com largura suficiente |

Use SVG por padrão. O PNG existe por compatibilidade e não deve ser
redimensionado repetidamente para produzir novos arquivos.

## Construção do ícone

- Prancheta: **512 × 512** unidades.
- Proporção: **1:1**.
- Tela: limites aproximados de `x = 30–482` e `y = 61–361`.
- Base: ocupa toda a largura e termina em aproximadamente `y = 452`.
- Código: recorte transparente centralizado dentro da tela.
- Camadas editáveis: `layer-terminal` e `layer-base`.

O SVG foi vetorizado a partir do PNG oficial, preservando sua silhueta e seus
recortes. Edite a fonte vetorial e gere novos rasters a partir dela.

## Construção do logotipo

O logotipo horizontal reúne:

- o símbolo oficial em 192 × 192 unidades;
- um intervalo de 48 unidades;
- o nome `SetupVibe` convertido em contornos a partir de JetBrains Mono
  SemiBold;
- uma prancheta de 1032 × 256 unidades.

Não digite o nome novamente por cima do logotipo, troque a fonte ou altere a
distância entre símbolo e wordmark.

## Cores

Os arquivos canônicos são monocromáticos:

| Elemento | Valor |
| --- | --- |
| Símbolo e wordmark | preto `#000000` |
| Código interno | transparente |
| Área externa | transparente |

Em fundo branco, o recorte do código aparece branco. Não aplique gradiente,
textura, duotone ou cores diferentes dentro do mesmo arquivo.

## Área de proteção

Use como unidade `x` a margem de **32 unidades** do logotipo horizontal.
Preserve ao menos:

- `1x` em todos os lados do ícone;
- `1x` ao redor do logotipo;
- a distância interna original entre símbolo e wordmark.

Texto, borda, outro logo ou recorte de imagem não entra nessa área.

## Tamanho mínimo

- Ícone digital: **32 × 32 px**.
- Ícone impresso: **8 × 8 mm**.
- Logotipo digital: **160 px** de largura.
- Cabeçalho de README: ícone com **128 px**.

Use apenas o ícone quando a assinatura horizontal ficar menor que o limite ou
não couber com a área de proteção.

## Fundos

- Em fundo branco ou muito claro, use os arquivos diretamente.
- Em fundo escuro, colorido, fotográfico ou texturizado, use uma placa branca
  que inclua a área de proteção.
- Não use `filter: invert()`.
- Não permita que o fundo reduza a leitura do terminal, do código ou do nome.

Não existe variante reversa oficial.

## Acessibilidade

- Preserve `role="img"`, `<title>` e `<desc>` nos SVGs.
- Use `alt="Logo do SetupVibe"` quando o ativo identificar a marca.
- Use `alt=""` quando o nome visível ao lado já tornar o símbolo decorativo.
- Garanta pelo menos 3:1 entre o preto do ativo e a superfície.
- Não use apenas o logo para comunicar uma ação ou estado.

## Usos incorretos

- Não distorcer, girar, inclinar, espelhar ou recortar.
- Não alterar o símbolo de código.
- Não separar a tela da base.
- Não mudar o wordmark ou reconstruí-lo com texto vivo.
- Não adicionar sombra, brilho, contorno, volume, gradiente ou animação.
- Não recolorir partes isoladas.
- Não usar diretamente sobre fundo sem contraste.
- Não manter cópia divergente fora desta pasta.

## Checklist

- [ ] O ativo veio de `brand/logo/`.
- [ ] Ícone e logotipo preservam proporção e geometria.
- [ ] O preto e a transparência continuam intactos.
- [ ] Área de proteção e tamanho mínimo foram respeitados.
- [ ] O fundo oferece contraste suficiente ou recebeu placa branca.
- [ ] Texto alternativo ou rótulo acessível está presente.
- [ ] Nenhum efeito ou reconstrução foi aplicado.
