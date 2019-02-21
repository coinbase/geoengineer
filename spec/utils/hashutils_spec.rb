require_relative '../spec_helper'

describe("HashUtils") do
  describe '#remove_' do
    it 'removes keys from a hash that start with _' do
      expect(HashUtils.remove_({ "_asd" => :value })).to eq({})
    end
  end

  describe 'deep_dup' do
    it 'returns a hash that is deep duped' do
      a = {}
      b = { "a" => a }
      x = HashUtils.deep_dup(b)
      expect(x.object_id).to_not eq b.object_id
      expect(x["a"]).to_not eq a.object_id
    end
  end
end
