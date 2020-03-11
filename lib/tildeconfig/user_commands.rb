def mod name
  if !Tildeconfig::MODULES.has_key?(name)
    Tildeconfig::MODULES[name] = TildeMod.new
  end

  yield(Tildeconfig::MODULES[name])
end
