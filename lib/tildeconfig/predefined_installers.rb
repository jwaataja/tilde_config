def_installer :ubuntu do |packages|
  sh "sudo apt install #{packages.join(' ')}"
end
