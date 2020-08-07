# General
- Fix `file_glob`, currently, it copies all matching files into the exact same
  destination filepath, which is broken. Instead, this command should take a
  directory for its second argument and copy the files in there.
- Stop tests from writing to stdout.
- Add option that prevents overriding any existing files.

# Documentation
- Document the command line options.
- Make sure `--directory-merge-strategy` is documented.
- Make sure `--ignore-errors` is documented.
- Document the `directory` command how it relates to the `file` and `file_glob`
  commands (currently, `directory` is an alias for file, add check to prevent
  this?).
