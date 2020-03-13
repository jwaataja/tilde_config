def mod name
  if !Tildeconfig::MODULES.has_key?(name)
    Tildeconfig::MODULES[name] = Tildeconfig::TildeMod.new
  end

  yield(Tildeconfig::MODULES[name]) if block_given?
end
