# robots-dotfiles

The home environment for `robots` on Aurora, applied with standalone
[Home Manager](https://github.com/nix-community/home-manager). It installs
Brave, Git, and Neovim, and manages Noctalia's shared settings.

Aurora's [infra configuration](https://github.com/nullcopy/infra) provides
Niri, Noctalia, Alacritty, audio, and the default Niri keybindings. This repo
deliberately uses that system configuration rather than replacing it.

## Setup

Clone to `~/.config/dotfiles` and apply:

```sh
git clone https://github.com/nullcopy/robots-dotfiles ~/.config/dotfiles
nix run home-manager -- switch --flake ~/.config/dotfiles
```

Home Manager selects the `robots@aurora` entry automatically. After the first
switch, apply changes with:

```sh
home-manager switch --flake ~/.config/dotfiles
```

A checkout elsewhere can be linked to `~/.config/dotfiles` before the first
switch:

```sh
ln -sfn /path/to/robots-dotfiles ~/.config/dotfiles
```

## Git identity

Git reads machine-local settings from `~/.config/git/local`. Set an identity
there before making commits:

```sh
git config --file ~/.config/git/local user.name 'Your Name'
git config --file ~/.config/git/local user.email 'you@example.com'
```

## Desktop

Log in to the Niri session. Useful default bindings include:

| Binding | Action |
| --- | --- |
| `Mod+Space` | Application launcher |
| `Mod+T` | Terminal |
| `Mod+Q` | Close window |
| `Mod+Tab` | Window switcher |
| `Mod+Shift+Slash` | Show all keybindings |
| `Mod+Escape` | Session menu |

Brave is available through the launcher and as the default web browser.

## Noctalia config and state

Shared settings are out-of-store symlinks into this checkout, so edits there
are live without a rebuild:

- `config/noctalia/config.toml` → `~/.config/noctalia/config.toml`
- `app-state/noctalia/palettes/` → `~/.config/noctalia/palettes/`

The Settings UI writes machine-local overrides to
`~/.local/state/noctalia/settings.toml`, which loads last and is not tracked.
Choosing a wallpaper in the UI also stores that choice locally. To set a
declarative default instead, set `my.noctalia.wallpaper` in `home.nix` to an
absolute image path.

To share a UI change, copy the setting into `config/noctalia/config.toml`, or
inspect the merged result with `noctalia config export`. Remove the
corresponding local override to fall back to the shared value.

## Updates

From the checkout:

```sh
nix flake update
home-manager switch --flake ~/.config/dotfiles
```

Validate changes with:

```sh
nix flake check
nix fmt
```
