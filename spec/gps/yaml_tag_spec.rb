require_relative '../spec_helper'

describe GeoEngineer::GPS::YamlTag do
  test_yaml = `
  test_constants: !Ref constants:development:here
  test_node: !Ref test:test:here
  test_symbol_bug: !Ref :test:here
  test_flatten: !Flatten
    - 1
    - - 2
      - !Ref constants:development:here
    - !Ref test:test:here
  `

  it 'should parse and correctly resolve the Tags' do
  end
end