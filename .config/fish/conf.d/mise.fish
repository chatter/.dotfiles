  set -l mise (which mise)
  if [ "$mise" ]
    mise activate fish | source
  end
