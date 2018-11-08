# .vim

I'm tired of trying to remember how to do this.

Also, I have changed files on my MacBooks and my configurations are now way out of whack. I mean, totally, but that's a commit for later.

So, you've been using NeoVim, so instead of the normal vim symlink:

```
ln -s ~/.vim/.vimrc ~/.vimrc
```

so instead you will want to use:


```
mkdir ~/.config/nvim
ln -s ~/.vim/.vimrc ~/.config/nvim/init.vim
```

This is good because we really need to switch to the `.config` structure anyway.

First, you'll need to make the folders for swap and backup.

```
mkdir swapfiles
mkdir backfiles
```

Then you'll need to re-install Vundle so get it from GitHub.

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

After which you can launch `nvim` and use `:VundleInstall` to get _most_ of the stuff that you need installed, then tweak as needed.

Remember that there's going to be some major issues with fonts on a new set-up, such as Airline not having all the cute pictographs it should until you fix that.

But here's a start.
