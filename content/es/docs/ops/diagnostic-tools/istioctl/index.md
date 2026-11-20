---
title: Usar la herramienta de línea de comandos istioctl
description: Istio incluye una herramienta complementaria para depurar y diagnosticar despliegues del service mesh de Istio.
weight: 10
keywords: [istioctl,bash,zsh,shell,command-line]
aliases:
  - /help/ops/component-debugging
  - /docs/ops/troubleshooting/istioctl
owner: istio/wg-user-experience-maintainers
test: no
---

Puedes hacerte una idea de lo que hace cada componente inspeccionando sus
[registros](/es/docs/ops/diagnostic-tools/component-logging/) o examinando su interior mediante
[introspección](/es/docs/ops/diagnostic-tools/controlz/). Si eso no es suficiente,
los pasos siguientes explican cómo ver lo que ocurre por dentro.

La herramienta [`istioctl`](/es/docs/reference/commands/istioctl) es una utilidad de línea de comandos de configuración
que permite a los operadores de servicios depurar y diagnosticar sus despliegues del service mesh de Istio.
El proyecto Istio también incluye dos scripts útiles para `istioctl` que habilitan el autocompletado
en Bash y Zsh. Ambos scripts admiten los comandos de `istioctl` disponibles actualmente.

{{< tip >}}
`istioctl` solo tiene habilitado el autocompletado para los comandos que no están obsoletos.
{{< /tip >}}

## Antes de empezar {#before-you-begin}

Te recomendamos usar una versión de `istioctl` que coincida con la versión de tu control plane de Istio.
Usar versiones coincidentes ayuda a evitar problemas imprevistos.

{{< tip >}}
Si ya [descargaste la versión de Istio](/es/docs/setup/additional-setup/download-istio-release/), ya deberías
tener `istioctl` y no necesitas instalarlo de nuevo.
{{< /tip >}}

## Instalar {{< istioctl >}}

Instala el binario `istioctl` con `curl`:

1. Descarga la versión más reciente con el comando:

    {{< text bash >}}
    $ curl -sL https://istio.io/downloadIstioctl | sh -
    {{< /text >}}

1. Agrega el cliente `istioctl` a tu PATH en un sistema macOS o Linux:

    {{< text bash >}}
    $ export PATH=$HOME/.istioctl/bin:$PATH
    {{< /text >}}

1. Opcionalmente, puedes habilitar la [opción de autocompletado](#enabling-auto-completion) cuando trabajes con una consola bash o Zsh.

## Obtener una visión general de tu mesh {#get-an-overview-of-your-mesh}

Puedes obtener una visión general de tu mesh con el comando `proxy-status` o `ps`:

{{< text bash >}}
$ istioctl proxy-status
{{< /text >}}

Si falta un proxy en la lista de salida, significa que no está conectado actualmente a ninguna instancia de istiod y, por lo tanto,
no recibirá ninguna configuración. Además, si aparece marcado como desactualizado (stale), es probable que haya problemas de red o
que sea necesario escalar istiod.

## Obtener la configuración del proxy {#get-proxy-configuration}

[`istioctl`](/es/docs/reference/commands/istioctl) te permite obtener información
sobre la configuración del proxy con el comando `proxy-config` o `pc`.

Por ejemplo, para obtener información sobre la configuración de clusters de la instancia de Envoy en un pod específico:

{{< text bash >}}
$ istioctl proxy-config cluster <pod-name> [flags]
{{< /text >}}

Para obtener información sobre la configuración de bootstrap de la instancia de Envoy en un pod específico:

{{< text bash >}}
$ istioctl proxy-config bootstrap <pod-name> [flags]
{{< /text >}}

Para obtener información sobre la configuración de listeners de la instancia de Envoy en un pod específico:

{{< text bash >}}
$ istioctl proxy-config listener <pod-name> [flags]
{{< /text >}}

Para obtener información sobre la configuración de rutas de la instancia de Envoy en un pod específico:

{{< text bash >}}
$ istioctl proxy-config route <pod-name> [flags]
{{< /text >}}

Para obtener información sobre la configuración de endpoints de la instancia de Envoy en un pod específico:

{{< text bash >}}
$ istioctl proxy-config endpoints <pod-name> [flags]
{{< /text >}}

Consulta [Depuración de Envoy e Istiod](/es/docs/ops/diagnostic-tools/proxy-cmd/) para obtener más consejos sobre cómo interpretar esta información.

## Autocompletado de `istioctl` {#istioctl-auto-completion}

{{< tabset category-name="prereqs" >}}

{{< tab name="macOS" category-value="macos" >}}

Si usas el sistema operativo macOS con la shell Zsh en la terminal, asegúrate de que
el paquete `zsh-completions` esté instalado. Con el gestor de paquetes [brew](https://brew.sh)
para macOS, puedes comprobar si el paquete `zsh-completions` está instalado con el siguiente comando:

{{< text bash >}}
$ brew list zsh-completions
/usr/local/Cellar/zsh-completions/0.34.0/share/zsh-completions/ (147 files)
{{< /text >}}

Si recibes `Error: No such keg: /usr/local/Cellar/zsh-completion`,
instala el paquete `zsh-completions` con el siguiente comando:

{{< text bash >}}
$ brew install zsh-completions
{{< /text >}}

Una vez que hayas instalado `zsh-completions package` en tu sistema macOS, agrega lo siguiente a tu archivo `~/.zshrc`:

{{< text plain >}}
    if type brew &>/dev/null; then
      FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

      autoload -Uz compinit
      compinit
    fi
{{< /text >}}

Es posible que también tengas que forzar la regeneración de `zcompdump`:

{{< text bash >}}
$ rm -f ~/.zcompdump; compinit
{{< /text >}}

Además, si recibes advertencias `Zsh compinit: insecure directories`
al intentar cargar estos autocompletados, es posible que tengas que ejecutar esto:

{{< text bash >}}
$ chmod -R go-w "$(brew --prefix)/share"
{{< /text >}}

{{< /tab >}}

{{< tab name="Linux" category-value="linux" >}}

Si usas un sistema operativo basado en Linux, puedes instalar el paquete de autocompletado de Bash
con el comando `apt-get install bash-completion` en distribuciones de Linux basadas en Debian o
`yum install bash-completion` en distribuciones de Linux basadas en RPM, los dos casos más comunes.

Una vez instalado el paquete `bash-completion` en tu sistema Linux,
agrega la siguiente línea a tu archivo `~/.bash_profile`:

{{< text plain >}}
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Habilitar el autocompletado {#enabling-auto-completion}

Para habilitar el autocompletado de `istioctl` en tu sistema, sigue los pasos correspondientes a tu shell preferida:

{{< warning >}}
Necesitarás descargar la versión completa de Istio, que incluye los archivos de autocompletado (en el directorio `/tools`).
Si todavía no lo has hecho, [descarga la versión completa](/es/docs/setup/additional-setup/download-istio-release/) ahora.
{{< /warning >}}

{{< tabset category-name="profile" >}}

{{< tab name="Bash" category-value="bash" >}}

Instalar el archivo de autocompletado de bash

Si usas bash, el archivo de autocompletado de `istioctl` se encuentra en el directorio `tools`.
Para usarlo, copia el archivo `istioctl.bash` a tu directorio personal y luego agrega la siguiente línea
a tu archivo `.bashrc` para cargar el archivo de autocompletado con tabulador de `istioctl`:

{{< text bash >}}
$ source ~/istioctl.bash
{{< /text >}}

{{< /tab >}}

{{< tab name="Zsh" category-value="zsh" >}}

Instalar el archivo de autocompletado de Zsh

Si usas Zsh, el archivo de autocompletado de `istioctl` se encuentra en el directorio `tools`.
Copia el archivo `_istioctl` a tu directorio personal o a cualquier otro directorio que elijas
(actualiza el directorio en el fragmento de script siguiente) y carga el archivo de autocompletado de `istioctl`
en tu archivo `.zshrc` de la siguiente manera:

{{< text zsh >}}
source ~/_istioctl
{{< /text >}}

También puedes agregar el archivo `_istioctl` a un directorio incluido en la variable `fpath`.
Para ello, coloca el archivo `_istioctl` en un directorio existente del `fpath`
o crea un directorio nuevo y agrégalo a la variable `fpath` en tu archivo `~/.zshrc`.

{{< tip >}}

Si obtienes un error como `complete:13: command not found: compdef`,
agrega lo siguiente al principio de tu archivo `~/.zshrc`:

{{< text bash >}}
$ autoload -Uz compinit
$ compinit
{{< /text >}}

Si el autocompletado no funciona, vuelve a intentarlo después de reiniciar la terminal.
Si sigue sin funcionar, intenta restablecer la caché de autocompletado con
los comandos anteriores en tu terminal.

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

### Usar el autocompletado {#using-auto-completion}

Si el archivo de autocompletado de `istioctl` se instaló correctamente, pulsa la tecla Tab
mientras escribes un comando `istioctl` y debería mostrarte un conjunto de sugerencias de comandos
entre las que puedes elegir:

{{< text bash >}}
$ istioctl proxy-<TAB>
proxy-config proxy-status
{{< /text >}}
