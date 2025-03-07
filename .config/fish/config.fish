fish_config theme choose "tokyonight_moon"

if status is-interactive
  set -gx GPG_TTY (tty)
  abbr --add n nvim
  abbr --add vim nvim
  abbr --add cat bat
end

alias dotfiles="$(which git) --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
