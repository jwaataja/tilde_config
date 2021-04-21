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

    it 'selects basic options correctly' do
      prefixes = { 'y' => 'yes', 'n' => 'no' }
      expect(Interaction.select_option(prefixes, nil, 'y')).to eq('yes')
      expect(Interaction.select_option(prefixes, nil, 'yes')).to eq('yes')
      expect(Interaction.select_option(prefixes, nil, 'yy')).to eq('yes')
      expect(Interaction.select_option(prefixes, nil, 'n')).to eq('no')
      expect(Interaction.select_option(prefixes, nil, 'no')).to eq('no')
      expect(Interaction.select_option(prefixes, nil, 'other')).to be_nil
      expect(Interaction.select_option(prefixes, nil, '')).to be_nil
    end

    it 'selects the default option correctly' do
      prefixes = { 'y' => 'yes', 'n' => 'no' }
      expect(Interaction.select_option(prefixes, 'no', '')).to eq('no')
      expect(Interaction.select_option(prefixes, 'no', ' ')).to eq('no')
    end

    it 'selects the correct option when one option is a prefix of another' do
      prefixes = { 'ab' => 'ab', 'abc' => 'abcd' }
      expect(Interaction.select_option(prefixes, nil, 'a')).to be_nil
      expect(Interaction.select_option(prefixes, nil, 'ab')).to eq('ab')
      expect(Interaction.select_option(prefixes, nil, 'abcd')).to eq('abcd')
    end
  end
end
