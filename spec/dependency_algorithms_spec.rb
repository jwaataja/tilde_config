require 'tildeconfig'

include TildeConfig

describe DependencyAlgorithms do
  it 'should find a basic cycle' do
    g = { a: %i[b], b: %i[a] }
    valid = [%i[a b], %i[b a]]
    cycle = DependencyAlgorithms.find_cycle(g)
    expect(valid.include?(cycle)).to be_truthy
  end

  it 'should find a length 3 cycle' do
    g = { a: %i[b], b: %i[c], c: %i[a] }
    path = %i[a b c]
    valid = []
    path.size.times do
      valid << path.dup
      path.push(path.shift)
    end

    cycle = DependencyAlgorithms.find_cycle(g)
    expect(valid.include?(cycle)).to be_truthy
  end

  it 'should return nil when there is no cycle' do
    g = { a: %i[b], b: [] }
    expect(DependencyAlgorithms.find_cycle(g)).to be_nil
  end

  it 'should find a basic topological sort' do
    g = { a: %i[b], b: [] }
    sort = DependencyAlgorithms.topological_sort(g)
    expect(sort).to eq(%i[a b])
  end

  it 'should return nil when no topological sort exists' do
    g = { a: %i[b], b: %i[a] }
    expect(DependencyAlgorithms.topological_sort(g)).to be_nil
  end

  it 'should return nil with a length 3 cycle' do
    g = { a: %i[b], b: %i[c], c: %i[a] }
    expect(DependencyAlgorithms.topological_sort(g)).to be_nil
  end
end
