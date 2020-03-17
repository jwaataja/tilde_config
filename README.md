# tilde.config
DSL for managing user space configuration settings

[HW5.5 Slides](https://docs.google.com/presentation/d/1z6cgpZADoadWwKAxk07Pm_cPMlNM6Ut6KmN2kntYLi4/edit?usp=sharing)

[HW5.4 Document](https://docs.google.com/document/d/1vc3pySso0WUYom3mqbICaZFvgZp0FfTEhX26g6eaO50/edit?usp=sharing)

[HW5.3 Document](https://docs.google.com/document/d/1MDWj7eHZowquE_PKR8kccA7BAukDoNmrVssVaJJluIc/edit?usp=sharing)

[Proposal Document](https://docs.google.com/document/d/1EHTfP45b6x5dCoXL99iaWSdz9eBOa10NrwevSIOJLJM/edit?usp=sharing)

## Installation

To install tildeconfig, you must first install Ruby and Rake. Once you have
them, clone this repository with, `git clone
https://github.com/jwaataja/tildeconfig.git`.

Then run
```
rake build
```
You can then run
```
rake install
```
If that doesn't work, or you want to perform an install that doesn't require
root permissions, you can instead run
```
gem install --user-install pkg/tildeconfig-0.1.0.gem
```

## Tutorial

To use tildeconfig, you should have a main directory where all your
configuration files are stored.  This would usually be in a git repository. To
figure out what to do with your files, tildeconfig reads from a file in the root
of your directory called `tildeconfig`. This is file containing code in our DSL,
which is embedded in Ruby. Any valid tildeconfig code is also Ruby code.

### Modules

The basic abstraction of tildeconfig is a *module*. A module is a group of
related files, code, etc.  that configure one aspect of a user's system. As a
running example, we show how to use tildeconfig to create a Vim module.

To create a module use the `mod` command and pass the name of the module,
prefixed with a colon. In Ruby, this is called a "symbol" and is often used for
references in tildeconfig. To declare a vim module, you would write,
```ruby
mod :vim
```

To configure the settings of the module, you can add a block of code after the
declaration. To do this, you write
```ruby
mod :vim do |m|
  # Your code here.
  # You can refer to the module with "m"
end
```

To install this module, you can use the `tildeconfig` command line utility.
Navigate into your configuration directory and run
```
tildeconfig install
```

### Files

One of the primary purposes of a module is to manage a set of files to be
installed. For example, Vim has a configuration file called `.vimrc` To declare
a file on a module, use the `file` command and pass the path of the file you
want to install in your home directory.
```ruby
mod :vim do |m|
  m.file ".vimrc"
end
```

You can specify the installation directory as well. For example, I can install a
file for Vim's C language specific settings as follows
```ruby
mod :vim do |m|
  m.file "c.vim" ".vim/after/ftplugin/c.vim"
end
```

### Actions

The `tildeconfig` command line program can do more than install modules. It can
also uninstall them and update them. The `uninstall` command removes the files
installed by a module and the `update` command recopies the files for each
module. To uninstall all modules, run
```bash
tildeconfig uninstall
```
and to update them run,
```bash
tildeconfig update
```

You can add specific code to be executed when each of these actions is run by
calling the `uninstall` or `update` commands on a module and giving it code. For
example, with Vim we often run a command to get some files for the internet. To
run a shell command when the install action is run we use the `sh` command as
follows,
```ruby
mod :vim do |m|
  m.install do
    sh "git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
  end
end
```
Now, when we run `tildeconfig install` this command is run. Notice, now when we
run `tildeconfig update`, the command is not run because it's only necessary
when installing.

### System packages

It's useless to install Vim configuration files if Vim isn't installed.
Similarly, one of the above commands requires having git installed. We can tell
`tildeconfig` to install these automatically by using the `pkg_dep` command like
this.
```ruby
mod :vim do |m|
  m.pkg_dep "vim", "git"
end
```

This tells tildeconfig to install the "vim" and "git" packages on the user's
system using a package manager. But for this to work, we must first tell it what
the names of the packages we want on our system are. For example, on Ubuntu we
may want to install "vim-gtk". To specify what the name of a package is on a
given system, you can use the `def_package` command.
```ruby
def_package "vim",
  :ubuntu => "vim-gtk"

def_package "git",
  :ubuntu => "git"
```

Note, Ubuntu is already defined in tildeconfig. You can define your own system
by telling it how to install packages. For this you will have to understand a
little bit of Ruby. The command is `def_installer` and you must tell it how to
install packages on that system. For example, to add support for Arch Linux we
would write,
```ruby
def_installer :arch do |packages|
  sh "sudo pacman -S #{packages.join(' ')}"
end
```

We could then modify the package definitions to include Arch Linux:
```ruby
def_package "vim",
  :ubuntu => "vim-gtk",
  :arch => "vim"

def_package "git",
  :ubuntu => "git",
  :arch => "git"
```

By default, tildeconfig doesn't install any packages. To install all package
dependencies when installing, run
```ruby
tildeconfig --packages --system ubuntu
```
You can specify a different system from `ubuntu` but you must define it
manually.

### Dependencies

Sometimes modules must be installed in a specific order, or one should always be
installed when another is. To specify that a module depends on another, you can
add `=> [dependencies]` to its definition. For example, the program neovim is a
rewrite of Vim. It can use many of the same configuration files as Vim, so we
might want to specify that Vim should be installed whenever neovim is. That is,
neovim *depends* on Vim. To do this we would write
```ruby
mod :vim

mod :neovim => [:vim]
```

Now, the `vim` module will always be installed before `neovim` when we run
`tildeconfig install`.

### Custom commands

You can extend the tildeconfig language by adding custom commands that may be
called on modules. We do this with the `def_cmd` command. You can then give it a
parameter list inside two `|` characters and then a block of code. The first
parameter passed to your command will always be a module.

For example, say we have many modules that install pip packages. All of these
modules depend on `python` and each time we have to manually write the shell
command used to install pip commands. For pip we might write,
```ruby
def_cmd :pip_req |m, *pkgs| do
  m.pkg_dep "python"
  m.install do
    sh "pip install #{pkgs.join(" ")}"
  end
end
```

Then in a new module we can use this module command.
```ruby
mod :my_mod do |m|
  m.pip_req "numpy"
end
```

### Full Examples

To run the examples, navigate into one of the subdirectories of the `examples`
folder in this repository. Then run `tildeconfig install`. WARNING: This may
override existing files on your system. It is recommended to run them on a
virtual machine.

For examples with system package dependencies, assuming you're on Ubuntu you
should instead run, `tildeconfig install --packages --system ubuntu`. If you
want to use a different package manager, you must define it manually.

#### Shell

This is a basic example. We first tell tildeconfig to install the ".zshrc" file into the home
directory and to run the `chsh -s zsh` command when installing.

```ruby
# Define a module called "shell"
mod :shell do |m|
  # Install the ".zshrc" file to the home directory
  m.file ".zshrc"
  m.install do
    # Run the shell command "chsh -s zsh" when installing this module.
    sh "chsh -s zsh"
  end
end
```

#### Vim
```ruby
# Create a module called vim
mod :vim do |m|
  # Install the packages "vim" and "git" using the system's package manager.
  m.pkg_dep "vim", "git"
  # Install these files. By default they are installed to the same path under
  # the home directory as they're located under the configuration file, but
  # c.vim is installed into a different location.
  m.file ".vimrc"
  m.file "c.vim", ".vim/after/ftplugin/c.vim"
  # Anything specified here is run when the module is actually installed using
  # the command line tool.
  m.install do
    # Run the following shell command.
    sh "git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim"
  end
end

# Create a module called "neovim" that depends on "vim". This means vim will
# always be installed first.
mod :neovim => [:vim] do |m|
  m.pkg_dep "neovim"
  m.file ".nvimrc"
end

# Defines a package called "vim" that can be installed with the pkg_dep
# command. Each line after the first says what the package is called on a given
# system.
def_package "vim",
  :ubuntu => "vim-gtk",
  :arch => "vim"

def_package "git",
  :ubuntu => "git",
  :arch => "git"

# Define a new system that packages can be installed on, called "arch", which is
# short for Arch Linux.
def_installer :arch do |packages|
  # Install packages on Arch linux using the following shell command.
  sh "sudo pacman -S #{packages.join(" ")}"
end

def_package "neovim",
  :ubuntu => "neovim",
  :arch => "neovim"
```

#### Python and Pip

```ruby
# Define a command called "pip_req" that can be run on modules. The first
# argument passed to this command is always the module it was called on.
def_cmd :pip_req |m, *pkgs| do
  # Modules this command is called on will depend on python and pip.
  m.pkg_dep "python3", "pip"
  m.install do
    # This is the command that installs pip packages. Now it doesn't have to be
    # written for each module that uses it individually.
    sh "pip install --user #{pkgs.join(" ")}"
  end
end

mod :my_mod do |m|
  # After defining the command, it can be called on modules.
  m.pip_req "numpy"
end

# Tell tildeconfig what each package is called under ubuntu
def_package "python3",
    :ubuntu => "python3"

def_package "pip",
    :ubuntu => "python3-pip"
```

## Testing

To install testing packages locally, use

```
bundle install --path vendor/bundle
# (path isn't too important)
```

then run tests using

```
bundle exec rspec spec
```
