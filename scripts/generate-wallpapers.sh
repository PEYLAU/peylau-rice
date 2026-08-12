#!/bin/bash
# Genera los fondos del tema iOS Glass.
#
# Truco: se dibuja una rejilla MINUSCULA (4x3 pixeles) con los colores en su
# sitio y se amplia a 1920x1080 con interpolacion. Al escalar x480 la
# interpolacion se convierte en un degradado continuo entre los pixeles: es la
# forma mas corta de conseguir un "mesh gradient" sin librerias de graficos.
#
# Despues se le mete un grano muy fino. Un degradado sintetico perfecto crea
# bandas visibles (banding) en pantallas de 8 bits, y el ruido las rompe.
set -euo pipefail

OUT=${1:?uso: mkwall.sh <directorio-destino>}
mkdir -p "$OUT"

gen() {
  local nombre=$1 && shift
  local pixeles=("$@")

  # -size 4x3 + xc: no vale para pintar pixel a pixel; se construye la rejilla
  # como texto PPM, que magick lee directo desde stdin.
  {
    echo "P3"
    echo "4 3"
    echo "255"
    for hex in "${pixeles[@]}"; do
      printf "%d %d %d\n" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
    done
  } | magick ppm:- \
    -filter Cubic -resize 1920x1080\! \
    -attenuate 0.55 +noise Gaussian \
    -quality 95 "$OUT/$nombre"

  echo "  $OUT/$nombre"
}

# Azules profundos con una diagonal de indigo. El equivalente oscuro del
# wallpaper por defecto de iOS.
gen 1-aurora.jpg \
  0B1026 14325F 24265C 0D1730 \
  123A6B 1E6FD9 6C46E0 15294D \
  0B1026 0E3557 2E2159 0B1026

# Mas calido: violeta a magenta. Hace que el `vibrancy` del blur se note mucho.
gen 2-twilight.jpg \
  120A20 33165A 5C1B55 1A0C2B \
  2A1147 7B2FC9 B23A86 2C1250 \
  120A20 1F0F38 40163F 120A20

# Verde azulado frio, para cuando el azul canse. Es el mas oscuro de los tres:
# deja el maximo contraste al texto blanco sobre los paneles.
gen 3-abyss.jpg \
  06131A 0A3040 0B4A4A 071A22 \
  0C3A4E 108196 12A38C 0A2C3A \
  06131A 082633 0A3F3C 06131A
