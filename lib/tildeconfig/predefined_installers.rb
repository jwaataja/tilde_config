##
# Runs the TildeConfig code to create the predefined installers available to the
# user.
def define_predefined_installers
  def_installer :ubuntu do |packages|
    sh "sudo apt install #{packages.join(' ')}"
  end
end
