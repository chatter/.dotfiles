fish_config theme choose "tokyonight_moon"

if status is-interactive
  abbr --add n nvim
  abbr --add vim nvim

  set -l mise (which mise)
  if [ "$mise" ]
    mise activate fish | source
  end
end

alias dotfiles="$(which git) --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
