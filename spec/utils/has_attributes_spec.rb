require_relative '../spec_helper'

describe("HasAttributes") do
  class WithAttributes
    include HasAttributes
    attr_reader :block_handled
    def assign_block(name, *args, &block)
      @block_handled = name
    end
  end

  describe('#[]') do
    it 'should return array of arrays' do
      x = WithAttributes.new
      x[:id] = "1"
      expect(x[:id]).to eq "1"
    end
  end

  describe('#terraform_attributes') do
    it 'should return a hash of attributes' do
      x = WithAttributes.new
      x.id = "1"
      expect(x.terraform_attributes.length).to eq 1
      expect(x.terraform_attributes["id"]).to eq "1"
    end

    it 'should remove attribute _terraform_id' do
      x = WithAttributes.new
      x._terraform_id = "1"
      x.id = "1"
      expect(x.terraform_attributes.length).to eq 1
    end

    it 'should remove attributes starting with _' do
      x = WithAttributes.new
      x._private_id = "1"
      x.id = "1"
      expect(x.terraform_attributes.length).to eq 1
    end

    it 'should remove attributes where values are nil' do
      x = WithAttributes.new
      x.id = nil
      expect(x.terraform_attributes.length).to eq 0
    end

    it 'should convert resources values to references (including in arrays)' do
      x = WithAttributes.new
      x.reference = GeoEngineer::Resource.new("type", "idd")
      expect(x.terraform_attributes["reference"]).to eq "${type.idd.id}"
    end
  end

  describe('bad attributes') do
    it 'timeout attribute should work' do
      x = WithAttributes.new
      x.timeout = 10
      expect(x.timeout).to eq 10
    end
  end

  describe('#method_missing') do
    it 'should call assign_block if a block is passed' do
      x = WithAttributes.new
      expect(x.block_handled).to eq nil
      x.block {
        block true
      }
      expect(x.block_handled).to eq 'block'
    end

    it 'should assign an attribute (with and without equals)' do
      x = WithAttributes.new
      x.attribute = "asd"
      x.other_attribute "sdf"
      expect(x.attribute).to eq "asd"
      expect(x.other_attribute).to eq "sdf"
    end

    it 'should assign multiple attributes as an array' do
      x = WithAttributes.new
      x.attribute = 1, 2, 3
      x.other_attribute 3, 4, 5
      expect(x.attribute).to eq [1, 2, 3]
      expect(x.other_attribute).to eq [3, 4, 5]
    end

    it 'should assign a Proc and lazy evaluate and cache the value' do
      x = WithAttributes.new
      called_count = 0
      x.attribute = -> {
        called_count += 1
        "awesome"
      }
      expect(called_count).to eq 0
      expect(x.attribute).to eq "awesome"
      expect(called_count).to eq 1
      expect(x.attribute).to eq "awesome"
      expect(called_count).to eq 1
    end

    it 'should delete an attribute' do
      x = WithAttributes.new
      x.attribute = "asd"
      expect(x.attribute).to eq "asd"
      x.delete(:attribute)
      expect(x.attribute).to eq nil
    end

    it 'should be usable with []' do
      x = WithAttributes.new
      x.attribute = "asd"
      expect(x["attribute"]).to eq "asd"
      expect(x[:attribute]).to eq "asd"
    end

    it 'allows you to reset already evaluated values' do
      example = WithAttributes.new
      example.tags = { Name: 'foo' }
      example.attribute = -> { example.tags[:Name] }
      expect(example.attribute).to eq('foo')
      expect(example.attributes['attribute']).to eq('foo')

      example.tags[:Name] = 'bar'
      example.reset
      expect(example.attributes['attribute']).to be_nil
      expect(example.attribute).to eq('bar')
    end

    it 'allows you to eagerly load all lazy attributes' do
      example = WithAttributes.new
      example.lazy1 = -> { "foo" }
      example.lazy2 = -> { "bar" }
      expect(example.attributes.count).to eq(0)
      example.eager_load
      expect(example.attributes.count).to eq(2)
    end
  end
end
