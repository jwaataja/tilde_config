* Add a method that validates all code run by the user. That is, if they have a `def_package`
  command that references a non-existent installer, it should raise an error.
* Add directory command to modules analogous to file command.
* Add an option to make installing dependencies optional. Fix how dependencies are currently handled
  where if you select a subset of modules only a certain number will be installed. Need to use dfs
  or something like that.
* Add option for what to do when one command fails.
* Add ability to specify config file from command line and also load "tildeconfig.rb" by default
