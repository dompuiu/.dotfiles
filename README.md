# .dotfiles

## Prerequisites

- [Homebrew](https://brew.sh/)
- FiraCode Nerd Font form [NerdFonts](https://www.nerdfonts.com/font-downloads)

## NVIM Config

- [LazyVim](https://www.lazyvim.org/installation)
- [tree-sitter-cli](https://www.npmjs.com/package/tree-sitter-cli)

## Tools

- Shells
  - [zsh](https://www.zsh.org/)
- [starship](https://starship.rs/) - Prompt theme engine
- Tools
  - [fd](https://github.com/sharkdp/fd)
  - [fzf](https://github.com/junegunn/fzf)
  - [ripgrep (rg)](https://github.com/BurntSushi/ripgrep)
  - [bat](https://github.com/sharkdp/bat)
  - [eza](https://github.com/eza-community/eza)
  - [zoxide](https://github.com/ajeetdsouza/zoxide)
  - [lazygit](https://github.com/jesseduffield/lazygit)
  - [tmux-sessionizer](https://github.com/jrmoulton/tmux-sessionizer)
  - [delta](https://github.com/dandavison/delta)
  - [hammerspoon](https://www.hammerspoon.org/)
  - [jq](https://jqlang.org/) - JSON processor (used by herdr plugins)

## Herdr

- [herdr](https://herdr.dev/) 0.8.2+ - terminal workspace manager (`.config/herdr`)
- [hunk](https://hunk.dev/) - diff viewer for `herdr-hunk`
- [tsk](https://gettsk.sh) - task board for `herdr-tsk`

### Plugins

Local plugins live in `.config/herdr/plugins`. Link them all so
herdr loads them straight from the repo:

```sh
bin/herdr-link-plugins          # macOS / Linux
```

```powershell
bin/herdr-link-plugins.ps1      # Windows
```

The script links every directory with a `herdr-plugin.toml`, prints `linked <name>` or `failed <name>` for each one, and is safe to re-run after adding a plugin.

| Plugin                                                                                                | Keys                                                   | Requires      | Optional    |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------- | ----------- |
| `herdr-sesh` - workspace picker (open workspaces, saved sessions, zoxide) and previous-workspace jump | `prefix+o`, `prefix+;`                                 | fzf 0.65+, jq | zoxide, eza |
| `herdr-hunk` - hunk diff picker, live diff and agent-idle autodiff                                    | `prefix+i`, `prefix+shift+i`, `prefix+d`, `ctrl+alt+a` | hunk, fzf, jq |             |
| `herdr-nvim` - nvim side pane                                                                         | `prefix+v`                                             | nvim          |             |

Plugin scripts use zsh on macOS/Linux and
[PowerShell 7](https://github.com/PowerShell/PowerShell) (`pwsh`) on Windows;
jq is not needed on Windows. A Nerd Font is needed for the picker icons.

`herdr-sesh` saved sessions go in `$(herdr plugin config-dir herdr-sesh)/sessions`,
one `name | path | startup command` per line;
see `.config/herdr/plugins/herdr-sesh/sessions.example`.
