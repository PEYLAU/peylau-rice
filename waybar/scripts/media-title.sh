#!/bin/bash
# Titulo de lo que esta sonando.
#
#   media-title.sh externo|interno
#
# Sustituye al modulo "mpris" que trae waybar, porque los modulos internos no
# saben ocultarse segun el monitor y aqui hace falta.
#
# Devuelve JSON, asi que el modulo lleva "return-type": "json".

set -u

source "$(dirname "$(readlink -f "$0")")/media-lib.sh"

LARGO=32   # equivalente al "dynamic-len" que tenia el modulo mpris

vacio() { echo '{"text": "", "class": "idle"}'; exit 0; }

# Si esta barra no es la principal, callarse cuanto antes: asi ni siquiera
# llegamos a lanzar playerctl.
es_mi_barra "${1:-interno}" || vacio

# UNA sola llamada a playerctl para todos los datos. Antes eran cinco llamadas
# (status, title, artist, album, playerName) cada dos segundos y por barra.
# El titulo va el ultimo a proposito: con IFS, `read` mete todo lo que sobra
# en la ultima variable, asi que un titulo con "|" no descoloca el resto.
IFS='|' read -r estado jugador artista album titulo <<<"$(
  playerctl metadata --format '{{status}}|{{playerName}}|{{artist}}|{{album}}|{{title}}' 2>/dev/null
)"

[[ $estado == Playing || $estado == Paused ]] || vacio
[[ -n $titulo ]] || vacio

# Mismo juego de iconos que tenia el modulo mpris.
case $jugador in
  spotify)          icono="󰓇" ;;
  firefox | zen*)   icono="󰈹" ;;
  chromium | brave) icono="󰊯" ;;
  mpv)              icono="󰐹" ;;
  *)                icono="󰝚" ;;
esac
[[ $estado == Paused ]] && icono="󰏤"

texto=$titulo
[[ -n $artista ]] && texto="$titulo  ·  $artista"
(( ${#texto} > LARGO )) && texto="${texto:0:LARGO}…"

# Los titulos traen de todo: comillas, barras invertidas y sobre todo "&" y
# "<", que waybar interpreta como marcado Pango y le revientan el modulo.
# Hay que escapar para Pango primero y para JSON despues.
limpiar() {
  printf '%s' "$1" |
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' \
        -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
    tr -d '\n'
}

pista=$(limpiar "$texto")
tip=$(limpiar "$jugador · ${estado,,}")\\n$(limpiar "$titulo")\\n$(limpiar "$artista")\\n$(limpiar "$album")

printf '{"text": "%s  %s", "tooltip": "%s", "class": "%s"}\n' \
  "$icono" "$pista" "$tip" "${estado,,}"
