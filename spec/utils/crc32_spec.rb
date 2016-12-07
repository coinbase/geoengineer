require '../spec_helper'

describe 'Crc32' do
  describe "hashcode" do
    it "should match the output from Terraform's Go Implementation" do
      expect(Crc32.hashcode("0.0.0.0/0")).to eq(1_080_289_494)
      expect(Crc32.hashcode("10.60.0.0/16")).to eq(2_056_622_336)
    end
  end
end
