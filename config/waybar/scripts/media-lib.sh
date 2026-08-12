#!/bin/bash
# Funciones compartidas por los modulos del reproductor.
#
# Este fichero se carga con `source`, NO se ejecuta. La diferencia importa:
# ejecutarlo lanzaria un proceso nuevo cada vez, y esto se consulta varias
# veces por segundo.

# ¿Hay alguna pantalla externa conectada?
#
# Se lee de /sys/class/drm en lugar de llamar a `hyprctl monitors`, porque el
# `read` de bash sobre un fichero no lanza ningun proceso y hyprctl si. Los
# nombres de los conectores coinciden con los de Hyprland (eDP-1, HDMI-A-1).
hay_externo() {
  local f estado
  for f in /sys/class/drm/card*-*/status; do
    case $f in
      *eDP* | *LVDS* | *DSI* | *Writeback*) continue ;;
    esac
    read -r estado <"$f" 2>/dev/null || continue
    [[ $estado == connected ]] && return 0
  done
  return 1
}

# ¿Le toca a esta barra dibujar el reproductor?
#
# El reproductor vive siempre en el monitor principal: el externo si hay
# alguno conectado, y el del portatil cuando esta solo. Hace falta esto porque
# waybar no sabe limitar un modulo a un monitor -- el "output" solo se puede
# poner a la barra entera, asi que las dos cargan los mismos modulos y cada
# una les pasa su papel.
es_mi_barra() {
  case ${1:-interno} in
    externo) hay_externo ;;
    interno) ! hay_externo ;;
    *) return 1 ;;
  esac
}

# Reproductores cuyo audio nos interesa para el visualizador. Zen es un fork
# de Firefox y se identifica ante MPRIS como "firefox".
NUESTROS='spotify firefox'

# ¿Esta sonando alguno de ellos? Una sola llamada a playerctl para todos, en
# vez de una por reproductor.
alguno_sonando() {
  local nombre estado
  while IFS='=' read -r nombre estado; do
    [[ $estado == Playing ]] || continue
    case " $NUESTROS " in
      *" $nombre "*) return 0 ;;
    esac
  done < <(playerctl -a metadata --format '{{playerName}}={{status}}' 2>/dev/null)
  return 1
}
