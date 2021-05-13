# thingskatedid style prompt
PS1='%(?.%(!.#.;).%F{6}%B;%b%f) '

# history
export HISTSIZE=""
export HISTFILESIZE=""
export HISTFILE="$HOME/.history"
export SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups

# 256 color scheme support
export TERM="xterm-256color"

#'rm *' sanity check
setopt RM_STAR_WAIT

# tab-completion
autoload -U compinit
compinit

# better looking completion style
zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'

# command correction
setopt correctall

# allows Bash style comments on command line
setopt interactivecomments

# more globbing
setopt extendedglob

# spelling corrector
setopt CORRECT

# make sure that if a program wants you to edit
# text, that Vim is going to be there for you
export EDITOR="vim"
export USE_EDITOR=$EDITOR
export VISUAL=$EDITOR

# aliases
source ~/.zsh_aliases

# get fasd working
eval "$(fasd --init posix-alias zsh-hook)"

# might be redundant b/c of version in .bashrc
fasd_cache="$HOME/.fasd-init-zsh"
if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
    fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >| "$fasd_cache"
fi
source "$fasd_cache"
unset fasd_cache

# 2015-07-27
# Dr. Bunsen
# add vim support in zsh

# vi style incrmental search
bindkey '^R' history-incremental-search-backward
bindkey -M viins \C-R history-incremental-search-backward
bindkey -M vicmd \C-R history-incremental-search-backward
# bindkey '^S' history-incremental-search-forward
# bindkey '^P' history-search-backward
# bindkey '^N' history-search-forward

# move inside a directory w/out cd
setopt AUTO_CD

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="philips"
ZSH_THEME=""

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git poetry web-search vi-mode zsh-autosuggestions) # NB: vi-mode and virtualenv are incompatible
# plugins=(git web-search virtualenv)

ZSH_DISABLE_COMPFIX="true" # ignore insecure directories
source $ZSH/oh-my-zsh.sh

# Powerline-shell
# if [[ -r /usr/share/powerline/bindings/zsh/powerline.zsh ]]; then
#     source /usr/share/powerline/bindings/zsh/powerline.zsh
# fi

# Zsh autocompletion of teamocil
compctl -g '~/.teamocil/*(:t:r)' teamocil

# r library
export R_LIBS_USER=~/R/rlibs
export R_LIBS=~/R/rlibs

# update julia packages
# usage: jl_up
jl_up() { julia -e "using Pkg; Pkg.update()" }

# precompile julia packages
# usage: jl_pc
jl_pc() { julia -e "using Pkg; Pkg.precompile()" }

# install library from CRAN using all cpus
# usage: r_install ggplot2
r_install() { Rscript -e "try(install.packages('$1', Ncpus = parallel::detectCores(), repos = 'https://cloud.r-project.org/', local = FALSE))" }
# install script from github using all cpus
# usage: r_install_github tidyverse/tidyverse
r_install_github() { Rscript -e "try(remotes::install_github('$1', threads = parallel::detectCores(), local = FALSE, force = TRUE))" }
# install script from github using all cpus
# usage: r_install_github_url https://github.com/tidyverse/tidyverse
r_install_github_url() { 
  pkg=$(gh_pkg $1)
  r_install_github $pkg
}
# update R github packages
# usage: r_up_gh
r_up_gh() { Rscript -e "try(moonmisc::update_github())" }
# update R packages
# usage: r_up
r_up() { Rscript -e "try(update.packages(Ncpus = parallel::detectCores(), repos = 'https://cloud.r-project.org/'))" }
# extract user/package from github url
# usage: gh_pkg https://github.com/ledell/subsemble
gh_pkg() { echo "$1" | sed "s#https://github.com/##" }
# r pkg installer
# inputs: packagename or username/packagename or https://github.com/username/packagename
rinstall() { 
  if [[ "$1" == *"github.com"* ]]; then
    pkg=$(gh_pkg $1)
    r_install_github $pkg
  elif [[ "$1" == *"/"* ]]; then
    r_install_github $1
  else
    r_install $1
  fi
}

# add cargo to path
export PATH="$HOME/.cargo/bin:$PATH"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# capslock remap
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'

# zsh syntax highlighting
source $HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# thefuck
eval $(thefuck --alias)

# cuda
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-10.1/lib64"
export PATH="/usr/local/cuda-10.1/bin:$PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64"
export PATH="/usr/local/cuda/bin:$PATH"

# Add julia to path
export PATH=/usr/local/bin/julia:$PATH
export PATH=$HOME/.julia/bin:$PATH
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/R/lib/" # for julia 1.4 and RCall

# purescript
# NB: must be AFTER `source $ZSH/oh-my-zsh.sh`
# fpath+=("$HOME/.zsh/pure")
# autoload -U promptinit; promptinit
# prompt pure

# spark
export SPARK_HOME="$HOME/spark"

# julia
export R_LD_LIBRARY_PATH="$HOME/julia"

# choosenim
export PATH=$HOME/.nimble/bin:$PATH

# airflow
export AIRFLOW_HOME=$HOME/airflow

# virtualenv for pure prompt
# source /usr/local/lib/node_modules/pure-prompt/pure.zsh

# nvm
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# lazydockr
alias lzd='lazydocker'

export PATH=$PATH:~/.local/bin

# starship
# eval $(starship init zsh)

# opencv
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3

# venv
# usage:
#   $ venv .recsys
function venv {
    default_envdir=".env"
    envdir=${1:-$default_envdir}

    if [ ! -d $envdir ]; then
        python3.9 -m virtualenv -p python3.9 $envdir
        echo -e "\x1b[38;5;2m✔ Created virtualenv $envdir\x1b[0m"
        source $envdir/bin/activate
        echo -e "\x1b[38;5;2m✔ Activated virtualenv $envdir\x1b[0m"
        pip install ipython ipykernel jupyter jupyterlab black flake8
        echo -e "\x1b[38;5;2m✔ Installed packages \x1b[0m"
	python -m ipykernel install --user --name=$envdir --display-name="Python 3.9 ($envdir)"
        echo -e "\x1b[38;5;2m✔ Created kernel 'Python3.7 ($envdir)'\x1b[0m"
	export PYTHONPATH=$(pwd)
    fi
    
    if [ -d $envdir ]; then
        source $envdir/bin/activate
        echo -e "\x1b[38;5;2m✔ Activated virtualenv $envdir\x1b[0m"
	export PYTHONPATH=$(pwd)
    fi

    python --version
}

# usage:
#   $ venv_lite .recsys
function venv_lite {
    default_envdir=".env"
    default_pyversion="3.9"
    envdir=${1:-$default_envdir}
    pyversion=${2:-$default_pyversion}

    if [ ! -d $envdir ]; then
        python$pyversion -m virtualenv -p python$pyversion $envdir
        echo -e "\x1b[38;5;2m✔ Created virtualenv $envdir\x1b[0m"
        source $envdir/bin/activate
        echo -e "\x1b[38;5;2m✔ Activated virtualenv $envdir\x1b[0m"
        pip install ipython ipykernel jupyter jupyterlab
        echo -e "\x1b[38;5;2m✔ Installed packages \x1b[0m"
	python -m ipykernel install --user --name=$envdir --display-name="Python ($envdir)"
        echo -e "\x1b[38;5;2m✔ Created kernel 'Python$pyversion ($envdir)'\x1b[0m"
	export PYTHONPATH=$(pwd)
    fi
    
    if [ -d $envdir ]; then
        source $envdir/bin/activate
        echo -e "\x1b[38;5;2m✔ Activated virtualenv $envdir\x1b[0m"
	export PYTHONPATH=$(pwd)
    fi

    python --version
}

# kitty
autoload -Uz compinit
compinit
kitty + complete setup zsh | source /dev/stdin

# poetry
export PATH="$HOME/.poetry/bin:$PATH"

# for bazelisk
export PATH="$PATH:$(go env GOPATH)/bin"

# for teamocil
export GEM_HOME=$HOME/.gem
export PATH="$PATH:$GEM_HOME/bin"
