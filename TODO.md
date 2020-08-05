- Add `directory` command that behaves like `file` but accept directories. This
  will involve coming up with a merge policy for the destination, i.e. what to
  do if install location exists and a directory, does it replace or recursively
  merge them?
- Make `file_glob` correctly handle directories. Currently, it will probably
  give an error if it matches a directory and tries to install it.
