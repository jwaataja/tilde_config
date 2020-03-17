# tilde.config
DSL for managing user space configuration settings

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
Similarly 

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
