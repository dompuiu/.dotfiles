# .dotfiles

My terminal setup for macOS, with partial Windows support: zsh, Neovim, terminal
emulators, multiplexers, git and a few macOS automation tools. Everything shares
the same font (FiraCode Nerd Font) and theme (Tokyo Night).

## How it works

The repo mirrors your home folder. Every file in it is symlinked to the same
path under `$HOME`, so editing a config in `~/.config` edits the repo:

```text
~/.dotfiles/.config/nvim/init.lua  ->  ~/.config/nvim/init.lua
~/.dotfiles/.zshenv                ->  ~/.zshenv
```

`bin/`, `plugins/` and `README.md` are not linked.

## Install

1. Install the [prerequisites](#prerequisites).
2. Clone the repo to `~/.dotfiles`.
3. Link everything:

   ```sh
   ~/.dotfiles/bin/install            # macOS / Linux
   ```

   ```powershell
   ~\.dotfiles\bin\install.ps1        # Windows
   ```

4. Open a new terminal. On first start zsh installs its plugin manager
   ([zi](https://github.com/z-shell/zi)) and plugins by itself.
5. Optional: [link the herdr/tuios plugins](#plugins).

New files added to the repo are not linked automatically; run the install
script again.

## Scripts

| Script                       | What it does                                                                                                     |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `bin/install`                | Symlinks every repo file into `$HOME`, creating folders as needed. `--force` runs `bin/clean` first.             |
| `bin/install.ps1`            | Windows version. Skips files that already exist unless `-Force`. Also sets `XDG_CONFIG_HOME` to `~\.config` (`-SkipXdg` to opt out). |
| `bin/clean`                  | Removes the links `install` created. See below.                                                                  |
| `bin/clean.ps1`              | Windows version of `clean`. Supports `-WhatIf` for a dry run.                                                    |
| `bin/link-plugins`           | Links the plugins in `plugins/` into herdr and/or tuios, whichever is installed, and unlinks stale ones (`.ps1` for Windows). |

### What `clean` removes

`clean` only removes things the dotfiles created:

- Symlinks in `$HOME` that point into this repo. Real files are never deleted.
- Folder symlinks that point into the repo, e.g. `~/.config/opencode -> ~/.dotfiles/.config/opencode`.
  Only the link is removed, never the repo files behind it.
- Broken symlinks in `~/.config` that point into the repo, e.g. links to files
  deleted from the repo.
- Folders left empty after removing those links.

Run it before deleting or moving files in the repo, or afterwards to clear the
broken links.

## What's configured

### Shell

| Path                         | Tool                                                     | Notes                                                                                                                       |
| ---------------------------- | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `.zshenv`                    | zsh                                                      | XDG folders, moves zsh config to `~/.config/zsh`, `EDITOR=nvim`, fzf/ripgrep defaults.                                      |
| `.config/zsh/.zshrc`         | zsh                                                      | `PATH`, zi plugins (autosuggestions, syntax highlighting, fzf-tab, forgit), zoxide, starship and aliases.                   |
| `.config/personal/env.zsh`   | zsh                                                      | Helper functions used by `.zshrc` (`addPath`, `checkIfCommandExists`, ...).                                                 |
| `.config/starship.toml`      | [starship](https://starship.rs/)                         | Prompt.                                                                                                                     |

Aliases worth knowing: `ls` → eza, `cat` → bat, `find` → fd, `cd` → zoxide
(the originals stay available as `realls`, `realcat` and `realfind`). `z`
starts zellij, and `z <layout>` starts it with a layout such as `oc` or `cc`.

Machine-specific settings go in `~/.zshenv.local` and `~/.zshrc.local`. They are
loaded when present and are not part of the repo.

### Editor

| Path            | Tool                                   | Notes                                                                                                 |
| --------------- | -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `.config/nvim`  | [LazyVim](https://www.lazyvim.org/)    | Tokyo Night, gitsigns, markdown preview, and `ctrl+h/j/k/l` navigation shared with tmux.              |

### Terminals and multiplexers

| Path                     | Tool                                           | Notes                                                                           |
| ------------------------ | ---------------------------------------------- | ------------------------------------------------------------------------------- |
| `.config/ghostty/config` | [Ghostty](https://ghostty.org/)                | Main terminal. Starts zsh, follows the system light/dark theme.                 |
| `.wezterm.lua`           | [WezTerm](https://wezterm.org/)                | Alternative terminal. On Windows it opens WSL (Ubuntu 24.04) by default.        |
| `.config/tmux/tmux.conf` | [tmux](https://github.com/tmux/tmux)           | Prefix `ctrl+z`. `prefix ctrl+o` opens tmux-sessionizer.                        |
| `.config/zellij`         | [zellij](https://zellij.dev/)                  | Starts locked. Layouts: `oc` (opencode + lazygit) and `cc` (claude + lazygit). Includes a sessionizer plugin. |
| `.config/herdr`          | [herdr](https://herdr.dev/)                    | Terminal workspace manager. See [Herdr and tuios](#herdr-and-tuios).                |
| `.config/tuios`          | [tuios](https://tuios.dev/)                    | herdr's keys on top of the tuios defaults; runs the [plugins](#plugins) unchanged. |

### Git and CLI tools

| Path                         | Tool                                                   | Notes                                                       |
| ---------------------------- | ------------------------------------------------------ | ----------------------------------------------------------- |
| `.gitconfig`                 | git                                                    | Aliases (`git aliases` lists them), rebase on pull.         |
| `.config/git/ignore`         | git                                                    | Global ignore file.                                         |
| `.config/lazygit/config.yml` | [lazygit](https://github.com/jesseduffield/lazygit)   |                                                             |
| `.config/fd/ignore`          | [fd](https://github.com/sharkdp/fd)                    | Global ignore file.                                         |
| `.config/ripgrep/ripgreprc`  | [ripgrep](https://github.com/BurntSushi/ripgrep)       | Loaded through `RIPGREP_CONFIG_PATH`.                       |
| `.config/opencode`           | [opencode](https://opencode.ai/)                       | Settings, TUI settings and a Tokyo Night Moon theme.        |

### macOS automation

| Path                      | Tool                                                    | Notes                                                                             |
| ------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `.hammerspoon/init.lua`   | [Hammerspoon](https://www.hammerspoon.org/)             | `cmd+esc` toggles Ghostty and jumps back to the previous app. `ctrl+alt+cmd+arrows` snaps windows. |

## Prerequisites

- [Homebrew](https://brew.sh/)
- FiraCode Nerd Font from [Nerd Fonts](https://www.nerdfonts.com/font-downloads)
- [zsh](https://www.zsh.org/) and [starship](https://starship.rs/)
- [Neovim](https://neovim.io/), [LazyVim](https://www.lazyvim.org/installation) and
  [tree-sitter-cli](https://www.npmjs.com/package/tree-sitter-cli)
- CLI tools: [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf),
  [ripgrep](https://github.com/BurntSushi/ripgrep), [bat](https://github.com/sharkdp/bat),
  [eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide),
  [lazygit](https://github.com/jesseduffield/lazygit), [delta](https://github.com/dandavison/delta),
  [jq](https://jqlang.org/)
- [tmux-sessionizer](https://github.com/jrmoulton/tmux-sessionizer) (`tms`). `.zshrc` loads its completions.
- Optional, picked up when installed: [mise](https://mise.jdx.dev/),
  [bob](https://github.com/MordechaiHadad/bob) (Neovim versions), pnpm, Rust (`~/.cargo/bin`).
- The terminal, multiplexer and macOS tools you want from the tables above.

## Herdr and tuios

- [herdr](https://herdr.dev/) 0.8.2+ - terminal workspace manager (`.config/herdr`)
- [tuios](https://tuios.dev/) - terminal window manager (`.config/tuios`); runs herdr plugins as they are
- [tuicr](https://github.com/agavra/tuicr) - code review TUI for the `tuicr` plugin

### Plugins

Local plugins live in `plugins/`, outside `.config`, because both herdr and
tuios load them. Link them all so they load straight from the repo:

```sh
bin/link-plugins          # macOS / Linux
```

```powershell
bin/link-plugins.ps1      # Windows
```

The script checks which of herdr and tuios is on `PATH` and skips the missing
one. With herdr it runs `herdr plugin link` for every directory with a
`herdr-plugin.toml`. tuios also reads herdr's plugin list, so with both present
it only enables the plugins in tuios; with tuios alone it runs
`tuios plugins link --enable`. It prints `<host>: linked <name>` or
`<host>: failed <name>` per plugin and is safe to re-run after adding one.

Before linking, it removes plugins that point into this repo but no longer
match a folder in `plugins/` (renamed, moved or deleted), e.g. the old
`herdr-sesh` links from `.config/herdr/plugins`. In tuios it turns them off
first, then unlinks them from herdr. Plugins from elsewhere, like `herdr-tsk`,
are left alone. Run it from a terminal outside tuios, and again after moving
the repo.

| Plugin                                                                                                | Keys                                                   | Requires      | Optional    |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------ | ------------- | ----------- |
| `sesh` - workspace picker (open workspaces, saved sessions, zoxide) and previous-workspace jump | `prefix+alt+o`, `prefix+;`                                 | fzf 0.65+, jq | zoxide, eza |
| `tuicr` - tuicr review in a split or tab, and uncommitted-changes review                       | `prefix+alt+i`, `prefix+alt+shift+i`, `prefix+alt+d`       | tuicr, jq     |             |
| `nvim` - nvim side pane                                                                         | `prefix+alt+v`                                             | nvim          |             |

Plugin scripts use zsh on macOS/Linux and
[PowerShell 7](https://github.com/PowerShell/PowerShell) (`pwsh`) on Windows;
jq is not needed on Windows. A Nerd Font is needed for the picker icons.

`sesh` saved sessions go in `$(herdr plugin config-dir sesh)/sessions`,
one `name | path | startup command` per line;
see `plugins/sesh/sessions.example`. In tuios the picker labels open
sessions `tuios` and in herdr it labels them `herdr`.
