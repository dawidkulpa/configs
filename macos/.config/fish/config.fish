# fix path for when default shell is changed to fish
source ~/.zprofile

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test (uname -s) = "Darwin"
  set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
  set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
end

fzf_configure_bindings --git_status=\cs --history=\ch --variables=\cv --directory=\cf --git_log=\cg

starship init fish | source
thefuck --alias | source
zoxide init fish | source
