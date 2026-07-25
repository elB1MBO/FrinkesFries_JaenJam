# Especificaciones de Arte - Frinkes Fries (Jaen Jam)

Este documento contiene la lista de sprites (assets) necesarios para el juego, junto con sus dimensiones recomendadas basándonos en las físicas y colisiones actuales del código. Las medidas están pensadas para un estilo Pixel Art / 2D nítido.

> [!TIP]
> Los tamaños sugeridos son potencias de 2 (32x32, 64x64) o medidas estándar para evitar problemas de escalado y mantener una resolución consistente (pixel perfect). Siempre es mejor hacer el canvas un pelín más grande para que quepan animaciones.

---

## 1. Personaje Principal y Ataques

| Elemento | Tamaño Canvas (Recomendado) | Colisión Real (Radio) | Descripción / Concepto |
|---|---|---|---|
| **Virus (Jugador)** | `48x48` o `64x64` | `12 px` | Un virus con "pinchos" (peplómeros). Actualmente es verde, pero dale el toque que quieras. Necesitará animación de Idle y (opcional) de Movimiento. |
| **Proyectil Base** | `16x16` o `24x24` | `6 px` | Lo que dispara el jugador. Actualmente es como un "rayo" o "esputo" amarillento/verdoso. |
| **Célula Orbital** | `24x24` o `32x32` | `10 px` | Una mutación que crea una pequeña célula que orbita alrededor del jugador. |

---

## 2. Enemigos (Sistema Inmunológico)

| Elemento | Tamaño Canvas (Recomendado) | Colisión Real (Radio) | Descripción / Concepto |
|---|---|---|---|
| **Glóbulo Blanco (Base)** | `32x32` o `48x48` | `14 px` | Enemigo estándar que persigue al jugador. Aspecto gelatinoso, blanquecino/azulado, con núcleo. |
| **Macrófago (Tanque)** | `64x64` o `80x80` | `24 px` | Enemigo grande, lento y con mucha vida. Es un fagocito (ameboide) grande, actualmente lo pintamos morado. Debe verse imponente. |
| **Linfocito B (Tirador)** | `32x32` o `48x48` | `12 px` | Enemigo a distancia. Célula azulada con "puntos" (receptores) en la superficie. Se queda quieto y dispara. |
| **Glóbulo Rojo (Piñata)** | `32x32` o `48x48` | `14 px` | Neutral. Disco bicóncavo (como un donut sin agujero), rojo oscuro. Rebota por la pantalla. |

---

## 3. Proyectiles Enemigos y Pickups

| Elemento | Tamaño Canvas (Recomendado) | Colisión Real (Radio) | Descripción / Concepto |
|---|---|---|---|
| **Anticuerpo (Proyectil)** | `24x24` o `32x32` | `6 px` | Disparado por el Linfocito B. Tiene forma de "Y" griega, color amarillento. |
| **Fragmento de ADN** | `24x24` o `32x32` | `12 px` | Es la moneda del juego. Actualmente es una pequeña doble hélice brillante (verde/cyan). |

---

## 4. Interfaz de Usuario (UI) e Iconos

Para la UI (Tienda, Subida de nivel, HUD), los iconos deberían tener un tamaño estándar, por ejemplo `64x64` píxeles, para que se vean bien dentro de las cartas.

### Iconos de Estadísticas (Level Up)
1. **HP Máximo** (Ej: Un corazón grande)
2. **Ataque** (Ej: Una espada cruzada o un colmillo viral)
3. **Defensa** (Ej: Un escudo o membrana celular)
4. **Velocidad de Ataque** (Ej: Un rayo o proyectiles múltiples)
5. **Velocidad de Movimiento** (Ej: Una bota o estela de velocidad)
6. **Robo de Vida** (Ej: Una gota de sangre con un "+" o colmillos vampíricos)
7. **Probabilidad Crítico** (Ej: Símbolo de explosión o diana)
8. **Suerte** (Ej: Trébol de cuatro hojas modificado o dados)

### Iconos de Mutaciones (Tienda)
1. **Pinchos Reactivos:** (Ej: Un virus erizado devolviendo daño).
2. **Célula Orbital:** (Ej: Un virus rodeado por un satélite celular).
3. **División Celular:** (Ej: Un proyectil partiéndose en dos).
4. **Membrana Reforzada:** (Ej: Un virus con un escudo brillante).
5. **Cápside Tóxica:** (Ej: Un aura verde de radiación o veneno alrededor del virus).
