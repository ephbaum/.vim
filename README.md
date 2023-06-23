# .vim

I'm tired of trying to remember how to do this.

#### Updated 22 June 2023

Now just rolling forward, check history for old setups

This install is happening on Ubuntu 20.04 WSL -- man would I love Arch under Windows :fingers-crossed: 

This go around I'm moving everything to live the `.config` folder as it's been long enough that I've been putting that work off. (I expect a relative file path update will accompany with README.md update)

Next I'll possibly get around to automating this. :rolling-eyes: 

### Initial Commands

- Create nvim config folder
    - `mkdir -p ~/.config/nvim`
- Navigate to nvim config folder
    - `cd ~/.config/nvim/`
- Clone Repo
    - `git clone git@github.com:fskirschbaum/.vim.git gitnvim`
- Symlink your `.vimrc` file you've so lovingly lavaflowed together over the years
    - `ln -s ~/.config/nvim/gitnvim/.vimrc ~/.config/nvim/init.vim`
- Create necessary folders
    - `mkdir swapfiles backfiles`

### How Plugins?`

Then follow the Neovim instructions to use [Vim Plug](https://github.com/junegunn/vim-plug)

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

After launching `nvim`:

`:PlugInstall:`

### After Care?

You'll want to install [Exuberant CTags](http://ctags.sourceforge.net/)

Under Ubuntu that's easy enough:

```
sudo apt install exuberant-ctags
```

Also, maybe install some node?

Other platforms: YMMV

### Add a Powerline Font 

Right now I'm fond of [FiraCode](https://github.com/tonsky/FiraCode), perhaps you'll be back on some other tip later

Under WSL2, adding this is now trivial through the Microsoft Terminal, and looks rather dope (especially with trransparency and scanlines and such :sweat_smile:):

![Screenshot of Microsoft Terminal window displaying NVIM running with FiraCode and Scanlines](images/nvim_fira_code_windows_terminal_gruvbox.png)
