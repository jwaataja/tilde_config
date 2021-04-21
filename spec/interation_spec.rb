module TildeConfig
  RSpec.describe Interaction do
    it 'can make a basic options prompt' do
      expect(Interaction.options_prompt('prompt?', %w[yes no], nil)[0])
        .to eq('prompt? [y]es,[n]o: ')
    end

    it 'can make a default option' do
      expect(Interaction.options_prompt('prompt?', %w[yes no], 'yes')[0])
        .to eq('prompt? [Y]es,[n]o: ')
    end

    it 'can make the other option the default' do
      expect(Interaction.options_prompt('prompt?', %w[yes no], 'no')[0])
        .to eq('prompt? [y]es,[N]o: ')
    end

    it 'can use more than two options' do
      expect(Interaction.options_prompt('prompt?', %w[yes no maybe], nil)[0])
        .to eq('prompt? [y]es,[n]o,[m]aybe: ')
    end

    it 'computes prefix correctly when longer than one character' do
      expect(Interaction.options_prompt('prompt?', %w[aab abb], nil)[0])
        .to eq('prompt? [aa]b,[ab]b: ')
    end

    it 'computes prefix correctly when one option is a prefix of another' do
      expect(Interaction.options_prompt('prompt?', %w[aab aabcd], nil)[0])
        .to eq('prompt? [aab],[aabc]d: ')
    end
  end
end
