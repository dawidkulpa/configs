# fix path for when default shell is changed to fish
source ~/.zprofile

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test (uname -s) = Darwin
    set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
    set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
end

fzf_configure_bindings --git_status=\cs --history=\ch --variables=\cv --directory=\cf --git_log=\cg

starship init fish | source
thefuck --alias | source
zoxide init fish | source
fnm env --use-on-cd --resolve-engines | source

set -l python_user_bin (python3 -m site --user-base)/bin
if test -d "$python_user_bin"
    fish_add_path "$python_user_bin"
end
