require_relative '../spec_helper'
require_relative './test_nodes'

describe GeoEngineer::GPS::Constants do
  it 'sets the name' do
    c = GeoEngineer::GPS::Constants.new({ "e": {} })
    expect(c.dereference("e", "name")).to eq "e"
  end

  context 'for_environment' do
    it 'returns all including _global but overrides' do
      c = GeoEngineer::GPS::Constants.new({
                                            "e": { "override": "no" },
                                            "_global": { "override": "yes", "test": "hello" }
                                          })
      expect(c.for_environment("e")["override"]).to eq "no"
      expect(c.for_environment("e")["test"]).to eq "hello"
    end
  end

  context 'dereference' do
    it 'looks in _global env' do
      c = GeoEngineer::GPS::Constants.new({ "e": {}, "_global": { "test": "hello" } })
      expect(c.dereference("e", "test")).to eq "hello"
    end

    it 'is overriden by env' do
      c = GeoEngineer::GPS::Constants.new({ "e": { "test": "no" }, "_global": { "test": "hello" } })
      expect(c.dereference("e", "test")).to eq "no"
    end

    it 'works with falsey values' do
      c = GeoEngineer::GPS::Constants.new({ "e": { "truthy?": true, "falsey?": false } })
      expect(c.dereference("e", "truthy?")).to eq true
      expect(c.dereference("e", "falsey?")).to eq false
    end

    it 'works with wildcards' do
      c = GeoEngineer::GPS::Constants.new({ "a": { "foo": 1 }, "b": { "foo": 2 } })
      expect(c.dereference("*", "foo")).to eq [1, 2]
    end
  end

  context 'yamltags' do
    it 'properly dereferences tags' do
      yaml = YAML.load("
_global:
  test: 'hello'
  test2: !ref constant::test
e1: {}
e2:
  test: 'no'
  test3: !ref constant::test
      ")
      c = GeoEngineer::GPS::Constants.new(yaml)
      expect(c.dereference("e1", "test")).to eq "hello"
      expect(c.dereference("e1", "test2")).to eq "hello"

      expect(c.dereference("e2", "test")).to eq "no"
      expect(c.dereference("e2", "test2")).to eq "hello"
      expect(c.dereference("e2", "test3")).to eq "no"
    end
  end
end
