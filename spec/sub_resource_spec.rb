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

        # i.e. can have sub resources as well
        foo {
          bar 20
        }

        foo {
          bar 40
        }
      }

      expect(sr.to_terraform_json[0]).to eq 'tags'
      expect(sr.to_terraform_json[1]['x']).to eq 10
      expect(sr.to_terraform_json[1]['foo'][0]['bar']).to eq 20
      expect(sr.to_terraform_json[1]['foo'][1]['bar']).to eq 40
    end
  end
end
