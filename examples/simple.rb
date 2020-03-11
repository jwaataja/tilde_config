mod :home do
    file ".zshrc"
    file "useful_cmd" ".bin/useful_cmd"
    pkg_dep "zsh"
    install do
        sh "chsh zsh"
    end
end

def_installer :ubuntu do |pkgs|
    sh "sudo apt install #{pkgs.join(" ")}"
end

def_package "python",
    ubuntu: "python3"
    debian: "python3"

mod :python_packages do
    pkg_dep "python"
    pip_req "numpy"
end

mod :all => [:home, :python_packages]

def_cmd :pip_req do |m, *pkgs|
    m.pkg_dep "python"
    m.install do
        sh "pip install #{pkgs.join(" ")}"
    end
end

mod :bin do
    root_dir "binaries"
    install_dir "~/.bin"
    file "useful_cmd"
end
