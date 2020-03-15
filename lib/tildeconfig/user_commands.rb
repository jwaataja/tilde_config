def mod name
  if !Tildeconfig::Globals::MODULES.key?(name)
    Tildeconfig::Globals::MODULES[name] = Tildeconfig::TildeMod.new
  end

  yield(Tildeconfig::Globals::MODULES[name]) if block_given?
end

def sh command
  system(command)
end
