source ~/.config/fish/environment.fish
source ~/.config/fish/themes/tokyonight_moon.fish

# Source local environment file if it exists
if test -f ~/environment.local.fish
    source ~/environment.local.fish
end

fish_add_path $HOME/.local/bin
fish_add_path $HOME/.local/share/bob/nvim-bin
fish_add_path $PNPM_HOME
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path $HOME/.cargo/bin

starship init fish | source
zoxide init fish --cmd cd | source
