def mod name
  if !Tildeconfig::MODULES.key?(name)
    Tildeconfig::MODULES[name] = Tildeconfig::TildeMod.new
  end

  yield(Tildeconfig::MODULES[name]) if block_given?
end

def sh command
  system(command)
end
