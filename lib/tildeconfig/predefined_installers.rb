def_installer :ubundu do |packages|
  sh "sudo apt install #{packages.join(' ')}"
end
