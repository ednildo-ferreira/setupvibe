# Marca SetupVibe

![Logotipo do SetupVibe](logo/logotype.svg)

Este diretório é a fonte normativa da identidade visual e verbal do SetupVibe.
A marca representa a preparação verificável de ambientes de desenvolvimento
por meio de scripts públicos, edições delimitadas e validação do resultado.

## Essência

**Posicionamento:** SetupVibe instala e configura ambientes de desenvolvimento
com scripts públicos para Desktop, Windows e Server.

**Promessa:** da máquina ao ambiente de trabalho, com cada mudança à vista.

**Tagline principal:** `Prepare. Revise. Desenvolva.`

### Personalidade

- **Operacional:** informa plataforma, ação e resultado.
- **Revisável:** mantém scripts, impacto e verificações visíveis.
- **Direta:** começa pelo que precisa ser feito ou confirmado.
- **Cautelosa:** declara permissões, limites e falhas possíveis sem
  dramatização.
- **Multiplataforma:** trata cada edição conforme seu escopo real.

## Conceito visual

O símbolo reúne uma janela de terminal, um recorte de código e a base de um
notebook:

- a janela representa o ambiente configurado;
- o código representa os scripts públicos;
- a base conecta a automação à máquina real;
- o desenho monocromático mantém a marca técnica e direta.

## Arquivos oficiais

| Arquivo | Uso |
| --- | --- |
| [`logo/icon.svg`](logo/icon.svg) | Símbolo vetorial preferencial |
| [`logo/icon.png`](logo/icon.png) | Fallback raster para integrações sem SVG |
| [`logo/logotype.svg`](logo/logotype.svg) | Assinatura horizontal com símbolo e nome |

O manual de construção, contraste, área de proteção, tamanho mínimo e usos
incorretos está em [`logo/LOGO.md`](logo/LOGO.md).

## Descrição e voz

[`description.md`](description.md) define posicionamento, promessa, tagline,
descrições institucionais, personalidade e limites da marca.

[`voice/voice.md`](voice/voice.md) define princípios, glossário, estrutura de
mensagens e exemplos para documentação, terminal, erro e comunicação pública.

## Uso rápido

- Use o SVG por padrão.
- Use o logotipo somente quando houver largura e proteção suficientes.
- Em fundos escuros ou complexos, aplique uma placa branca.
- Explique impacto antes de publicar comandos.
- Nomeie a edição e a plataforma quando elas mudarem o comportamento.
- Não prometa compatibilidade ou segurança absoluta.

## Brand Gate

Antes de publicar:

- [ ] posicionamento, promessa e voz permanecem coerentes;
- [ ] o ativo veio de `brand/logo/`;
- [ ] proporção, cor, transparência e área de proteção foram preservadas;
- [ ] o texto informa edição, plataforma, impacto e validação quando aplicável;
- [ ] limites e estados Beta continuam explícitos;
- [ ] fatos variáveis foram confirmados no repositório.

O checklist operacional completo está em [`checklist.md`](checklist.md).

## Fontes normativas

| Tema | Fonte |
| --- | --- |
| Descrição institucional | [`description.md`](description.md) |
| Manual do logo | [`logo/LOGO.md`](logo/LOGO.md) |
| Ícone vetorial | [`logo/icon.svg`](logo/icon.svg) |
| Fallback raster | [`logo/icon.png`](logo/icon.png) |
| Logotipo horizontal | [`logo/logotype.svg`](logo/logotype.svg) |
| Voz | [`voice/voice.md`](voice/voice.md) |
| Referência rápida | [`guidelines.md`](guidelines.md) |
| Brand Gate | [`checklist.md`](checklist.md) |

## Manutenção

Uma mudança de posicionamento, tagline, voz ou ativo precisa atualizar a fonte
especializada correspondente, este README e os pontos públicos que consomem a
marca. Não crie cópias divergentes dos SVGs.
