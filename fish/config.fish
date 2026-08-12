source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
#
# Sustituye al fish_greeting de cachyos (que llama a `fastfetch` a secas).
#
# El problema: fastfetch NO se adapta al ancho del terminal. Con esta config
# emite SIEMPRE lineas de 117 columnas: 54 del logo de
# ~/.config/omarchy/branding/about.txt, mas 8 de padding, mas las cajas de 54.
# En un terminal a media pantalla (~80 columnas) eso se envuelve y sale
# descuadrado. No es un problema de escala ni de fuente: al estirar la ventana
# no se "arregla", lo que pasa es que al reflujar el texto ya cabe y deja de
# haber envoltura.
#
# Por debajo del umbral se quita el logo, que es lo unico que sobra: sin el la
# salida ocupa 55 columnas y la informacion se conserva entera.
function fish_greeting
    # COLUMNS lo mantiene fish. Si no estuviera definido se prefiere la version
    # compacta antes que arriesgar el descuadre.
    set -l ancho 0
    if set -q COLUMNS
        set ancho $COLUMNS
    end

    if test "$ancho" -ge 117
        fastfetch
    else
        fastfetch --logo none
    end
end
