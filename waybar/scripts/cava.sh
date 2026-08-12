#!/bin/bash
# Visualizador de audio para waybar.
#
#   cava.sh externo|interno
#
# Waybar no trae el modulo "cava" compilado en Arch/CachyOS (lo confirma
# `module cava: Unknown module`), asi que lanzamos el programa cava en modo
# "raw" y traducimos cada nivel (0-7) al bloque unicode correspondiente.
#
# Este es el UNICO script del reproductor que se queda corriendo, porque tiene
# que mantener vivo a cava. Por eso lleva tres protecciones para no acumularse:
#
#   1) mata a cava y a su awk cuando termina  (trap)
#   2) sale si waybar, su padre, ha muerto    (comprobacion de PPID)
#   3) sale si waybar le ha cerrado la salida (awk muerto / echo fallido)
#
# Sin ellas, cada reinicio de waybar dejaba procesos huerfanos acumulandose.

set -u

DIR=$(dirname "$(readlink -f "$0")")
source "$DIR/media-lib.sh"

ROL=${1:-interno}

# Waybar, al reiniciarse, NO mata este script: solo le cierra la salida. Nos
# quedamos con quien es nuestro padre para poder detectar que se ha ido.
PADRE=$PPID

command -v cava >/dev/null || exit 0
command -v playerctl >/dev/null || exit 0

BARS="▁▂▃▄▅▆▇█"

CONFIG=$(mktemp -t waybar-cava.XXXXXX)
FIFO=$(mktemp -u -t waybar-cava-fifo.XXXXXX)
mkfifo "$FIFO"

CAVA_PID=""
AWK_PID=""

# Matar por PID explicito es la unica forma fiable: si lanzaramos la tuberia
# como `cava | awk &`, $! seria el PID de awk y cava quedaria vivo. Por eso
# cava escribe a un FIFO y awk lo lee, cada uno con su PID localizado.
parar() {
  [[ -n $CAVA_PID ]] && kill "$CAVA_PID" 2>/dev/null
  [[ -n $AWK_PID ]] && kill "$AWK_PID" 2>/dev/null
  CAVA_PID=""
  AWK_PID=""
}

limpiar() {
  parar
  rm -f "$CONFIG" "$FIFO"
}

# El EXIT limpia al salir por las buenas. Para las señales hace falta ademas
# el `exit` explicito: bash, despues de atender un trap, SIGUE ejecutando el
# bucle donde lo dejo. Sin ese exit el script sobrevive incluso a un `kill`.
trap 'limpiar' EXIT
trap 'limpiar; exit 0' INT TERM HUP

cat >"$CONFIG" <<EOF
[general]
bars = 10
framerate = 30
# Deja de procesar tras 1s de silencio, por si acaso.
sleep_timer = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

arrancar() {
  # Si ya hay uno vivo no lanzamos otro.
  [[ -n $CAVA_PID ]] && kill -0 "$CAVA_PID" 2>/dev/null && return

  cava -p "$CONFIG" >"$FIFO" &
  CAVA_PID=$!

  # awk traduce "0;3;5;7;" a bloques. fflush() es imprescindible: sin el, awk
  # acumula la salida en un buffer y waybar no ve nada durante minutos.
  awk -F';' -v bars="$BARS" '
    BEGIN { split(bars, B, "") }
    {
      out = ""
      for (i = 1; i < NF; i++) out = out B[$i + 1]
      print out
      fflush()
    }
  ' <"$FIFO" &
  AWK_PID=$!
}

while :; do
  # ¿Sigue vivo waybar? Si nos han reasignado a otro padre es que murio, y
  # nosotros sobramos. Se lee de /proc para no lanzar un `ps` cada dos
  # segundos. Campos de /proc/self/stat: 1=pid 2=nombre 3=estado 4=ppid.
  read -r _ _ _ ppid_actual _ </proc/self/stat
  [[ $ppid_actual == "$PADRE" ]] || exit 0

  # Y si waybar sigue vivo pero ha destruido ESTA barra (al desconectar el
  # monitor, por ejemplo), nos cierra la salida y awk muere de SIGPIPE.
  if [[ -n $AWK_PID ]] && ! kill -0 "$AWK_PID" 2>/dev/null; then
    exit 0
  fi

  # Se comprueba dentro del bucle, no antes: asi al conectar o desconectar el
  # monitor externo el visualizador salta de barra en un par de segundos, sin
  # tener que reiniciar waybar.
  if es_mi_barra "$ROL" && alguno_sonando; then
    arrancar
  else
    parar
    # Linea vacia = el modulo desaparece de la barra. Si el echo falla es que
    # waybar cerro la salida: nos vamos.
    echo "" || exit 0
  fi

  sleep 2
done
