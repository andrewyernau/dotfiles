# Zsh en Ubuntu / WSL

## Instalación replicable

En una máquina nueva:

```bash
git clone https://github.com/andrewyernau/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap/setup-wsl.sh
exec zsh -l
```

En esta máquina el repositorio ya está en `~/dotfiles`, con los cambios locales
pendientes de revisar y publicar. Ejecuta los tres últimos comandos desde tu
terminal WSL normal. El entorno del agente no permite instalar paquetes con
sudo; por tanto, la instalación y el cambio de shell todavía están pendientes.

`setup-linux.sh` delega en este instalador al detectar WSL. Puedes inspeccionar
el plan con `bash bootstrap/setup-wsl.sh --dry-run`. Usa `--no-default-shell`
para probar zsh sin cambiar el shell de inicio y `--no-packages` si ya tienes
las dependencias. El instalador es para Ubuntu/Debian, se ejecuta como usuario
normal y usa sudo únicamente para APT. `chsh` puede pedir tu contraseña.

Instala zsh, tmux, fzf, ripgrep, bat, zsh-autosuggestions y
zsh-syntax-highlighting con APT. Las versiones de estos paquetes dependen de
los repositorios de la distribución. Powerlevel10k se descarga desde un commit
fijado en el instalador; una instalación existente se conserva. No hace falta
Oh My Zsh ni una Nerd Font.

Enlaza `.zshrc`, `.zprofile`, `.p10k.zsh` y `.tmux.conf` con los archivos del
repositorio. Guarda los archivos sustituidos, incluidos enlaces previos, bajo
`~/.local/state/dotfiles/backups/<fecha>-<pid>` (respeta XDG_STATE_HOME).
Repetir el instalador no vuelve a sustituir enlaces que ya apuntan al repo.
La configuración bash actual se conserva. Docker, red, fail2ban, PowerShell y
Neovim se mantienen fuera de este instalador.

## Uso

| Tecla | Acción |
| --- | --- |
| Tab / Shift+Tab | Completar comandos, rutas y argumentos; recorrer candidatos |
| Flecha derecha / End | Aceptar una sugerencia del historial |
| Ctrl+R | Buscar comandos del historial con fzf |
| Ctrl+T | Elegir una sesión tmux o un proyecto |
| Ctrl+F | Abrir tmuxxer, si está instalado |
| Flechas arriba/abajo | Buscar en el historial por el prefijo escrito |
| Ctrl+izquierda/derecha | Mover el cursor entre palabras |
| Ctrl+arriba/abajo | Buscar en el historial por el prefijo escrito |

Ctrl+T busca proyectos bajo `~/code` y `~/setenova` si existen. Puedes cambiar
esas rutas en `~/.zshrc.local`; hay un ejemplo en `linux/zsh/local.example.zsh`.
El selector conserva los nombres de las sesiones existentes y añade un hash de
la ruta a las nuevas para distinguir proyectos con el mismo nombre.

Se mantienen NVM, Bun, Cargo y Conda si están instalados. Conda usa su script
compatible con zsh y queda disponible mediante `conda activate <entorno>`;
no activa `base` automáticamente. No se importa ni modifica el historial bash.
El historial zsh y las preferencias locales quedan fuera del repositorio.

El prompt conserva la distribución Pure de dos líneas y añade colores cálidos,
verdes y grises inspirados en [if-not-nil/dots](https://github.com/if-not-nil/dots).
La referencia utiliza fish; esta configuración está adaptada a zsh.

## Colores en Windows Terminal

El fondo y la paleta completa se configuran en Windows Terminal, no en zsh.
Añade el objeto de `windows/terminal/bark.scheme.json` al array `schemes` de
su `settings.json`. En el perfil Ubuntu/WSL selecciona `"colorScheme": "Bark"`.
No reemplaces tu settings.json con ese archivo: contiene solo un esquema.
El prompt funciona sin configurar la paleta; usa colores ANSI de 256 colores.

## Comprobar y publicar

Después de abrir una terminal nueva:

```zsh
print -r -- "$ZSH_VERSION"
getent passwd "$USER" | cut -d: -f7
whence -w conda nvm fzf_tmux_launcher
bindkey '^R'
bindkey '^T'
```

Prueba sugerencias escribiendo el inicio de un comando usado, Tab para completar
y Ctrl+R para buscar. Las sesiones tmux ya abiertas conservan su proceso bash;
ejecuta `exec zsh -l` en cada panel o crea una sesión nueva. Si tu perfil de
Windows Terminal lanza `bash` explícitamente, quita ese comando para que WSL
use el shell de inicio o lanza `wsl.exe -d Ubuntu --exec zsh -l` (adapta el nombre
de distribución).

```bash
cd ~/dotfiles
git diff --check
git diff
git status --short
git add README.md WSL.md .gitignore bootstrap/setup-linux.sh bootstrap/setup-wsl.sh linux/zsh linux/bin linux/tmux windows/terminal/bark.scheme.json
git commit -m "feat(zsh): add reproducible WSL setup and Bark-inspired styling"
git push origin main
```

Este checkout se recuperó con el conector GitHub y se verificó contra el commit
y el árbol originales; tiene historial superficial, como `git clone --depth=1`.
Su remoto es el repositorio original y permite commits y push normales.
Si necesitas todo el historial: `git fetch --unshallow origin`.

## Validación realizada en el entorno del agente

Se comprobaron la sintaxis de los scripts bash, el esquema JSON y la integridad
del checkout (`git fsck`). Pruebas aisladas con un HOME temporal verificaron
copias de seguridad, enlaces anteriores rotos, conservación de bash, segunda
ejecución sin nuevas copias y delegación del instalador WSL. El selector tmux
se probó con comandos simulados para adjuntar, cambiar y cancelar.
No se pudo validar la sintaxis ni el arranque real de zsh: el binario no está
instalado y este entorno no permite sudo. El instalador comprueba la sintaxis
de los tres archivos zsh antes de crear los enlaces.

## Volver atrás

Ejecuta `chsh -s /bin/bash` y abre una terminal nueva. Para deshacer también los
enlaces, localiza la copia de seguridad indicada por el instalador. Por cada
archivo, comprueba que el destino siga siendo un enlace a este repositorio,
retira ese enlace y mueve el archivo correspondiente de la copia a tu HOME.
Si el archivo no existía antes, basta con retirar el enlace. No elimines el
repositorio mientras haya enlaces a él. Reinicia tmux o recarga la configuración
restaurada para aplicar también su configuración anterior.
