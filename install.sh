#!/usr/bin/env bash
#
# Enlaza ~/.config a este repositorio.
#
# En lugar de copiar, se crean enlaces simbólicos: la configuración viva y la
# versionada pasan a ser el mismo fichero. Eso es lo que permite que
# `git status` detecte al vuelo lo que una actualización de Omarchy haya
# cambiado por debajo, que es la razón de ser del repo. Con copias habría que
# acordarse de sincronizar, y lo que no se automatiza se olvida.
#
#   ./install.sh          enlaza
#   ./install.sh --dry-run enseña lo que haría, sin tocar nada
#   ./install.sh --unlink  deshace los enlaces y restaura la última copia
#
set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DESTINO="${XDG_CONFIG_HOME:-$HOME/.config}"
RESPALDO="$DESTINO/peylau-rice-backups/$(date +%Y%m%d-%H%M%S)"

SIMULAR=0
DESENLAZAR=0
for arg in "$@"; do
  case $arg in
  --dry-run) SIMULAR=1 ;;
  --unlink) DESENLAZAR=1 ;;
  -h | --help)
    sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# \?//;$d'
    exit 0
    ;;
  *)
    echo "Opción desconocida: $arg" >&2
    exit 1
    ;;
  esac
done

# Rutas relativas a ~/.config. El nivel al que se enlaza NO es arbitrario:
#
#   - Los directorios de una sola aplicación se enlazan enteros.
#   - fish va por fichero: fish_variables lo reescribe fish sola, con rutas
#     absolutas de esta máquina, y no debe salir del equipo.
#   - De omarchy solo cuelgan subdirectorios, porque su carpeta contiene
#     además 'current', que son 7 MB de ficheros GENERADOS en cada cambio de
#     tema. Enlazar 'omarchy' entero metería esa churrería en el repo.
ENLACES=(
  hypr
  waybar
  walker
  mako
  swayosd
  alacritty
  foot
  kitty
  ghostty
  btop
  cava
  fastfetch
  uwsm
  starship.toml
  xdg-terminals.list
  fish/config.fish
  omarchy/themes/ios-glass
  omarchy/hooks
  omarchy/themed
  omarchy/branding
)

azul() { printf '\033[34m%s\033[0m\n' "$*"; }
verde() { printf '\033[32m%s\033[0m\n' "$*"; }
gris() { printf '\033[90m%s\033[0m\n' "$*"; }
rojo() { printf '\033[31m%s\033[0m\n' "$*" >&2; }

ejecutar() {
  if ((SIMULAR)); then
    gris "      $*"
  else
    "$@"
  fi
}

if ((DESENLAZAR)); then
  azul "Deshaciendo enlaces"
  for ruta in "${ENLACES[@]}"; do
    destino="$DESTINO/$ruta"
    # Solo se quita si apunta a ESTE repo. Un enlace que puso otra cosa no es
    # nuestro y no se toca.
    if [[ -L $destino ]] && [[ $(readlink -f "$destino") == "$REPO"/* ]]; then
      ejecutar rm "$destino"
      ejecutar cp -a "$REPO/config/$ruta" "$destino"
      verde "  restaurado  $ruta"
    else
      gris "  se omite    $ruta (no es un enlace a este repo)"
    fi
  done
  echo
  azul "Hecho. ~/.config vuelve a tener ficheros propios."
  exit 0
fi

azul "Enlazando ~/.config → $REPO/config"
((SIMULAR)) && gris "(simulación: no se escribe nada)"
echo

enlazados=0
respaldados=0

for ruta in "${ENLACES[@]}"; do
  origen="$REPO/config/$ruta"
  destino="$DESTINO/$ruta"

  if [[ ! -e $origen ]]; then
    rojo "  FALTA       $ruta (no está en el repo)"
    continue
  fi

  # Ya enlazado a donde toca: no hay nada que hacer. Esto es lo que hace que
  # el script se pueda volver a lanzar sin efectos raros.
  if [[ -L $destino ]] && [[ $(readlink -f "$destino") == "$(readlink -f "$origen")" ]]; then
    gris "  ya estaba   $ruta"
    continue
  fi

  # Hay algo real ahí. Nunca se borra: se aparta con marca de tiempo.
  if [[ -e $destino ]] || [[ -L $destino ]]; then
    ejecutar mkdir -p "$RESPALDO/$(dirname "$ruta")"
    ejecutar mv "$destino" "$RESPALDO/$ruta"
    respaldados=$((respaldados + 1))
  fi

  ejecutar mkdir -p "$(dirname "$destino")"
  ejecutar ln -s "$origen" "$destino"
  verde "  enlazado    $ruta"
  enlazados=$((enlazados + 1))
done

echo
azul "$enlazados enlazados, $respaldados apartados"
((respaldados > 0)) && gris "Lo que había antes está en $RESPALDO"

if ((SIMULAR)); then
  exit 0
fi

cat <<'FIN'

Para que surta efecto:

  hyprctl reload          recarga Hyprland
  omarchy restart waybar  reinicia la barra
  omarchy theme set "iOS Glass"

FIN
