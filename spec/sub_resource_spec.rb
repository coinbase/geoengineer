require_relative './spec_helper'

describe("GeoEngineer::SubResource") do
  it 'should work' do
    sr = GeoEngineer::SubResource.new(nil, 'tags') {
      x 10
    }
    expect(sr.x).to eq 10
  end

  describe '#to_terraform_json' do
    it 'should return a list, with key[0] value[1]' do
      sr = GeoEngineer::SubResource.new(nil, 'tags') {
        x 10
      }
      expect(sr.to_terraform_json[0]).to eq 'tags'
      expect(sr.to_terraform_json[1]['x']).to eq 10
    end
  end
end
