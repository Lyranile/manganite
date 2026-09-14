# Tokens
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.bun/bin:/usr/bin:/run/host/usr/bin:$HOME/go/bin:$PATH"
export HOMEBREW_NO_ENV_HINTS=1
export XDG_CONFIG_HOME="$HOME/.config"
export TANSTACK_CLI_TELEMETRY_DISABLED=1

SHELL=$(cat /proc/$$/comm)
find ~/.ssh -type f -name 'id_*' ! -name '*.pub' -exec ssh-add {} + >/dev/null 2>&1

# Starship
if [ "$(command -v starship)" ]; then
	eval "$(starship init ${SHELL})"
	eval "$(starship completions ${SHELL})"
fi


# Flatpak Aliases
if [ "$(command -v flatpak)" ]; then
	alias code="flatpak run com.vscodium.codium > /dev/null 2>&1"
	alias opencode="flatpak run ai.opencode.opencode > /dev/null 2>&1"
	alias emacs="flatpak run org.gnu.emacs"
	alias zed="flatpak run dev.zed.Zed -n"
	alias convert="flatpak run io.gitlab.adhami3310.Converter"
	alias bottles="flatpak run com.usebottles.bottles"
	alias godot="flatpak run org.godotengine.Godot"
	alias blender="flatpak run org.blender.Blender"
	alias inkscape="flatpak run org.inkscape.Inkscape"
	alias kodi="tv.kodi.Kodi"
	alias libreoffice="org.libreoffice.LibreOffice"
	alias zen="flatpak run app.zen_browser.zen"
	alias bitwarden="flatpak run com.bitwarden.desktop"
	alias discord="flatpak run org.equicord.equibop"
	alias freerdp="flatpak run com.freerdp.FreeRDP"
	alias rdp="freerdp"
	alias snoop="flatpak run de.philippun1.Snoop"
fi

# Git Aliases
if [ "$(command -v git)" ]; then
  alias gcp="!f() { git add -A && git commit -m \"$@\" && git push; }; f"
  alias gds="!f() { echo -n 'Are you sure you want to discard all local changes? (y/n) '; read ans; if [[ \"\$ans\" == 'y' ]]; then git reset --hard HEAD; else echo 'Aborted'; fi }; f"
  alias gup="!f() { current=\$(git branch --show-current); git fetch origin master; git checkout master; git pull origin master; git checkout \$current; git merge master; }; f"
  alias gam="!f() { git add -A && git commit --amend --no-edit; }; f"
fi

# Editor Aliases
if [ "$(command -v zed)" ]; then
	export EDITOR="zed"
	alias ezsh="$EDITOR ~/.zshrc"
	alias ebash="$EDITOR ~/.bashrc"
	alias eprofile="$EDITOR ~/.profile"
	alias esecrets="$EDITOR ~/.secrets"
fi

# List Aliases
if [ "$(command -v eza)" ]; then
	FLAGS="--git --icons=auto --classify --group-directories-first --time-style=long-iso --color-scale"
	alias ls="eza $FLAGS"
	alias l="eza $FLAGS --git-ignore"
	alias ll="eza $FLAGS --all --header --long"
	alias tree="eza $FLAGS --tree"
fi

# Zoxide Aliases
if [ "$(command -v zoxide)" ]; then
	eval "$(zoxide init ${SHELL})"
	alias cd="z"
fi

# Direnv Aliases
if [ "$(command -v direnv)" ]; then
	eval "$(direnv hook ${SHELL})"
fi

# Picker Aliases
if [ "$(command -v fzf)" ]; then
	eval "$(fzf --${SHELL})"
fi

# Atuin Aliases
if [ "$(command -v atuin)" ]; then
	eval "$(atuin init ${SHELL})"
fi

# Mise Aliases
if [ "$(command -v mise)" ]; then
	eval "$(mise activate ${SHELL})"
fi

# Cat Aliases
if [ "$(command -v bat)" ]; then
	alias less="bat"
	alias cat="bat --paging=never"
fi

# Processes Aliases
if [ "$(command -v duf)" ]; then
    alias ps='procs'
fi

# Node aliases
if [ "$(command -v npm)" ]; then
    alias npm='bun'
    alias npx='bunx'
fi

# Find Aliases
if [ "$(command -v fd)" ]; then
	alias find="fd"
fi

# Man Aliases
if [ "$(command -v tldr)" ]; then
	alias man="tldr"
fi

# Difference Aliases
if [ "$(command -v delta)" ]; then
	alias diff="delta"
fi

# Task Aliases
if [ "$(command -v go-task)" ]; then
	alias task="go-task"
fi

# AWS Aliases
if [ "$(command -v awscliv2)" ]; then
	alias aws="awscliv2"
fi

# DNF Aliases
if [ "$(command -v rpm-ostree)" ]; then
	alias dnf="rpm-ostree"
fi

# UMU Aliases
if [ "$(command -v umu-run)" ]; then
	alias umu="umu-run"
fi

# Grep Aliases
if [ "$(command -v ug)" ]; then
	alias grep='ug'
	alias egrep='ug -E'
	alias fgrep='ug -F'
	alias xzgrep='ug -z'
	alias xzegrep='ug -zE'
	alias xzfgrep='ug -zF'
fi

# Python Aliases
if [ "$(command -v python3)" ]; then
	alias python="python3"
	alias pip="pip3"
	alias py="python"
	alias pyuninstall="pip freeze | xargs pip uninstall -y"
	alias venv="source .venv/bin/activate"
fi

# UV Aliases
if [ "$(command -v uv)" ]; then
	alias pyinstall="uv tool install"
	alias pygrade="uv tool upgrade --all"
	alias pyclean="uv cache clean"
	alias pylist="uv tool list"
	eval "$(uv generate-shell-completion $SHELL)"
	eval "$(uvx --generate-shell-completion $SHELL)"
fi

# Git Aliases
if [ "$(command -v git)" ]; then
	alias gitadd="git add -A"
	alias gitreset="git reset --hard HEAD~1"
	alias gitpull="git pull --rebase"
	alias gitpush="git push"
	alias gitcommit="git commit -m"
	alias gitstatus="git status"
	alias gitbranch="git branch --list"
	alias gitclone="git clone"
	alias gitlog="git log --oneline --decorate --graph --all"
fi

# Docker Aliases
if [ "$(command -v docker)" ]; then
	alias ollama="docker exec -it ollama ollama $@"
	alias llama="docker exec -it llama llama $@"
	alias dock="docker compose"
	alias dockup="docker compose up -d"
	alias dockdown="docker compose down"
	alias dockexec="docker exec -it"
	alias dockps="docker compose ps -a"
	alias dockrm="docker compose rm"
	alias dockbuild="docker compose build"
	alias docklog="docker compose logs -f"
	alias dockres="docker compose restart"
	alias dockstop="docker compose stop"
	alias dockclean="docker system prune -af"
	alias dockimages="docker images"
	alias dockvolumes="docker volume ls"
	alias docknetworks="docker network ls"
	alias dockinspect="docker inspect"
	alias dockrestart="docker restart"
	alias docktop="docker top"
	alias dockstats="docker stats"
	alias docklogs="docker logs -f"
	alias dockpull="docker pull"
	alias dockpush="docker push"
	alias docktag="docker tag"
	alias docklogin="docker login"
	alias docklogout="docker logout"
	alias docksearch="docker search"
	alias dockhistory="docker history"
	alias dockpause="docker pause"
	alias dockunpause="docker unpause"
	alias dockkill="docker kill"
	alias dockstart="docker start"
	alias dockstopall="docker stop $(docker ps -aq)"
fi

# Kubernetes Aliases
if [ "$(command -v kubectl)" ]; then
	alias kube="kubectl"
	alias kubeget="kubectl get"
	alias kubedsc="kubectl describe"
	alias kuberes="kubectl rollout restart"
	alias kubepods="kubectl get pods"
	alias kubedeps="kubectl get deployments"
	alias kubestate="kubectl get statefulsets"
	alias kubenms="kubectl get namespaces"
	alias kubecont="kubectl config get-contexts"
	alias kubeexec="kubectl exec -it"
	alias kubedel="kubectl delete"
	alias kubelogs="kubectl logs -f"
	alias kubetail="kubectl logs -f --tail=100"
	alias kubewatch="kubectl get pods -w"
	alias kubeyaml="kubectl get -o yaml"
	alias kubefile="kubectl apply -f"
	alias kubewatch="kubectl get all -w"
	alias kubesvc="kubectl get services"
	alias kubeing="kubectl get ingress"
	alias kubepvc="kubectl get pvc"
	alias kubecm="kubectl get configmap"
	alias kubese="kubectl get secret"
	alias kubesa="kubectl get sa"
	alias kubesc="kubectl get sc"
	alias kubehpa="kubectl get hpa"
	alias kubepdb="kubectl get pdb"
	alias kubelb="kubectl get svc -o wide | grep LoadBalancer"
	alias kubetop="kubectl top pods"
	alias kubenodes="kubectl get nodes"
	alias kubewhoami="kubectl config current-context"
	alias kubediff="kubectl diff"
	alias kubecanary="kubectl set image deployment"
	alias kubeprev="kubectl rollout undo"
	alias kubeforward="kubectl port-forward"
	alias kubecp="kubectl cp"
fi
