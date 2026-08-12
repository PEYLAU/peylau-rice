#!/bin/bash
# Icono de play / pausa del reproductor.
#
#   media-playpause.sh externo|interno
#
# Sustituye a lo que habia antes en config.jsonc, que era una tuberia
# permanente: `playerctl status --follow | sed -u ...`. Aquello era elegante
# sobre el papel -- reaccionaba a eventos, sin sondear -- pero waybar no mata
# esos procesos al reiniciarse: solo les cierra la salida. Cada reinicio
# dejaba un playerctl y un sed vivos para siempre, y llegaron a acumularse 34.
#
# Un script que arranca, imprime y termina no puede quedarse colgado nunca.

set -u

source "$(dirname "$(readlink -f "$0")")/media-lib.sh"

es_mi_barra "${1:-interno}" || { echo ""; exit 0; }

case $(playerctl status 2>/dev/null) in
  Playing) echo "󰏤" ;;   # sonando -> el boton ofrece pausar
  Paused)  echo "󰐊" ;;   # en pausa -> el boton ofrece reanudar
  *)       echo "󰓛" ;;
esac
