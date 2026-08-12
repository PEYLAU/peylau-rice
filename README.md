# dotfiles

Configuración de escritorio de [Omarchy](https://omarchy.org/) (Arch + Hyprland).

El repositorio vive **dentro de `~/.config`**, no en una carpeta aparte con
enlaces simbólicos. La razón es que el objetivo no es solo respaldar, es
**detectar**: `omarchy update` ejecuta migraciones que a veces reemplazan
ficheros de `~/.config` por los valores por defecto, y con el repo aquí un
`git status` después de cada actualización lo canta al instante.

## Qué hay dentro

| Ruta | Qué es |
|---|---|
| `hypr/` | Hyprland: atajos, monitores, apariencia, idle y bloqueo |
| `waybar/` | Barra. Dos barras (interna/externa) + scripts del reproductor |
| `omarchy/themes/ios-glass/` | Tema propio de cristal esmerilado |
| `omarchy/hooks/` | Automatismos al cambiar de tema, tras actualizar, etc. |
| `walker/`, `mako/`, `swayosd/` | Lanzador, notificaciones y OSD |
| `alacritty/`, `foot/`, `kitty/`, `ghostty/` | Terminales |
| `btop/`, `cava/`, `fastfetch/`, `starship.toml` | Utilidades |

## Lista blanca, no lista negra

`~/.config` contiene también sesiones de navegador, cookies y tokens
(`chromium/`, `zen/`, `mozilla/`, `vesktop/`, `opencode/`). El `.gitignore`
ignora **todo** por defecto y readmite a mano solo lo que es configuración:

```gitignore
/*
!/hypr/
!/waybar/
...
```

Con una lista negra bastaría olvidar una entrada para publicar credenciales, y
en git eso no se arregla borrando el fichero después: se queda en el historial.

**Al añadir algo nuevo**: primero la línea `!/loquesea/`, después `git status`
y comprobar qué arrastra antes de commitear.

## Tema iOS Glass

Cristal esmerilado al estilo iOS/visionOS. Se aplica con:

```bash
omarchy theme set "iOS Glass"
```

Piezas que lo componen:

- **Blur de Hyprland** con `vibrancy` alto, que satura lo que queda detrás del
  panel. Es lo que más distingue el look de visionOS de un simple desenfoque.
- **Squircle**: `rounding_power = 4`. Con el 2 por defecto la esquina es un
  arco de circunferencia y se nota el cambio brusco al llegar al lado recto.
- **Transparencia de los terminales por el propio terminal** (`opacity` de
  alacritty), no con `active_opacity` de Hyprland. Este último atenuaría
  también el texto y dejaría la consola ilegible.
- **Animaciones con rebote** (bezier con punto de control por encima de 1) y
  `workspaces` activada, que Omarchy trae desactivada de serie.

Los fondos son degradados generados, no fotos: se dibuja una rejilla de 4x3
píxeles y se amplía a 1920x1080 con interpolación cúbica, lo que convierte los
saltos entre píxeles en un degradado continuo.

## Notas de mantenimiento

- `omarchy/current/` **no** se versiona: son ficheros generados por
  `omarchy theme set` a partir de `themes/` y las plantillas.
- Los `*.bak.<timestamp>` que deja `omarchy-refresh-config` tampoco.
- `looknfeel.conf` se lee **después** del `hyprland.conf` del tema, así que
  cualquier valor repetido en ambos gana desde `looknfeel.conf`. Hoy afecta a
  `rounding`, `rounding_power` y `gradient_rounding`.
