require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsWafIpset) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:waf) { AwsClients.waf }
    before do
      stub = waf.stub_data(
        :list_ip_sets,
        {
          ip_sets: [
            {
              ip_set_id: 'some_id',
              name: 'some_name'
            },
            {
              ip_set_id: 'some_id2',
              name: 'some_name2'
            }
          ]
        }
      )
      waf.stub_responses(:list_ip_sets, stub)
    end

    after do
      waf.stub_responses(:list_ip_sets, {})
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsWafIpset._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end

    it 'should validate_correct_cidr_blocks' do
      good_cidr1 = GeoEngineer::Resources::AwsWafIpset.new('name', 'id') {
        ip_set_descriptors {
          value "0.0.0.0/32"
        }
      }
      good_cidr2 = GeoEngineer::Resources::AwsWafIpset.new('name', 'id') {
        ip_set_descriptors {
          value "255.255.255.255/0"
        }
      }
      expect(good_cidr1.validate_correct_cidr_blocks.length).to eq 0
      expect(good_cidr2.validate_correct_cidr_blocks.length).to eq 0

      bad_cidr1 = GeoEngineer::Resources::AwsWafIpset.new('name', 'id') {
        ip_set_descriptors {
          value "0.0.0.0/33"
        }
      }
      bad_cidr2 = GeoEngineer::Resources::AwsWafIpset.new('name', 'id') {
        ip_set_descriptors {
          value "asdfasdf"
        }
      }

      expect(bad_cidr1.validate_correct_cidr_blocks.length).to eq 1
      expect(bad_cidr2.validate_correct_cidr_blocks.length).to eq 1
    end
  end
end
