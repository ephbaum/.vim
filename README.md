# .vim

I'm tired of trying to remember how to do this.

#### Updated 9 Sept 2021

Now just rolling forward, check history for old setups

This install is happening on Ubuntu 20.04 WSL -- man would I love Arch under Windows :fingers-crossed: 

This go around I'm moving everything to live the `.config` folder as it's been long enough that I've been putting that work off. (I expect a relative file path update will accompany with README.md update)

Next I'll possibly get around to automating this. :rolling-eyes: 

### Initial Commands

- Create nvim config folder
    - `mkdir ~/.config/nvim`
- Navigate to nvim config folder
    - `cd ~/.config/nvim/`
- Clone Repo
    - `git clone git@github.com:fskirschbaum/.vim.git gitnvim`
- Symlink your `.vimrc` file you've so lovingly lavaflowed together over the years
    - `ln -s ~/.config/nvim/gitnvim/.vimrc ~/.config/nvim/init.vim`
- Create necessary folders
    - `mkdir swapfiles`
    - `mkdir backfiles`

### How Plugins?`

Then follow the Neovim instructions to use [Vim Plug](https://github.com/junegunn/vim-plug)

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

After launching `nvim`:

`:PlugInstall:`

### Now What?

You've reached the end of this little guide. You'll probably need to battle to determine a way to get Powerline Fonts working... I have no idea how to do this uner WSL?

@TODO - Document Font Process When I Get Around To It
