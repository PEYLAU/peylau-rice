#!/bin/bash
# Barra de progreso + tiempo de la cancion en curso.
#
#   media-progress.sh externo|interno
#
# Va en un modulo custom de waybar con "return-type": "json" e "interval": 1.
# Cuando no hay nada sonando -- o cuando esta barra no es la principal --
# devuelve texto vacio, y waybar oculta el modulo en vez de dejar un hueco.

set -u

source "$(dirname "$(readlink -f "$0")")/media-lib.sh"

ANCHO=12
LLENO="━"
VACIO="─"
MANDO="●"

vacio() { echo '{"text": "", "class": "idle"}'; exit 0; }

# Comprobar el monitor ANTES de llamar a playerctl: en la barra secundaria
# esto se ejecuta cada segundo y no debe costar nada.
es_mi_barra "${1:-interno}" || vacio

# UNA sola llamada para los tres datos. Antes eran tres (status, position y
# metadata) cada segundo y por barra.
IFS='|' read -r estado pos_us dur_us <<<"$(
  playerctl metadata --format '{{status}}|{{position}}|{{mpris:length}}' 2>/dev/null
)"

[[ $estado == Playing || $estado == Paused ]] || vacio

# playerctl da los dos valores en microsegundos. A enteros en segundos para
# poder operar dentro de bash.
[[ $pos_us =~ ^[0-9]+$ ]] || vacio
[[ $dur_us =~ ^[0-9]+$ ]] || dur_us=0
pos=$(( pos_us / 1000000 ))
dur=$(( dur_us / 1000000 ))

reloj() { printf '%d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

# Las emisoras y streams no declaran duracion: sin ella no hay barra que
# dibujar, asi que mostramos solo el tiempo transcurrido.
if (( dur <= 0 )); then
  printf '{"text": "%s", "class": "%s"}\n' "$(reloj "$pos")" "${estado,,}"
  exit 0
fi

llenos=$(( pos * ANCHO / dur ))
(( llenos > ANCHO - 1 )) && llenos=$(( ANCHO - 1 ))

barra=""
for (( i = 0; i < ANCHO; i++ )); do
  if   (( i <  llenos )); then barra+=$LLENO
  elif (( i == llenos )); then barra+=$MANDO
  else                         barra+=$VACIO
  fi
done

printf '{"text": "%s  %s / %s", "class": "%s"}\n' \
  "$barra" "$(reloj "$pos")" "$(reloj "$dur")" "${estado,,}"
