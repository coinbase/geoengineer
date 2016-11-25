require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSecurityGroup") do
  common_resource_tests(GeoEngineer::Resources::AwsSecurityGroup, 'aws_security_group')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsSecurityGroup)

  describe "validations" do
    it 'should flatten cidr blocks (allows for easier definition)' do
      res = GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          cidr_blocks [[1], 2, [[3]]]
        }
      }
      res.flatten_cidr_and_sg_blocks
      expect(res.ingress.cidr_blocks).to eq [1, 2, 3]
    end

    it 'should validate_correct_cidr_blocks' do
      good_cidrs = GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          cidr_blocks ["0.0.0.0/32", '255.255.255.255/0']
        }
      }
      expect(good_cidrs.validate_correct_cidr_blocks.length).to eq 0

      bad_cidrs = GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          cidr_blocks ["0.0.0.0/33", '256.255.255.255/0', 'nonsence']
        }
      }

      expect(bad_cidrs.validate_correct_cidr_blocks.length).to eq 3
    end
  end

  describe "_terraform_id and _geo_id" do
    it 'should get geo_id from tags Name' do
      res = GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        tags {
          Name 'geo_id'
        }
      }
      expect(res._geo_id).to eq 'geo_id'
    end

    it 'should get terraform_id from remote by matching geo_ids' do
      GeoEngineer::Resources::AwsSecurityGroup.clear_remote_resource_cache
      remote_resources = [{ _geo_id: 'geo_id', _terraform_id: 't_id' }]
      allow(GeoEngineer::Resources::AwsSecurityGroup).to(
        receive(:_fetch_remote_resources).and_return(remote_resources)
      )

      res = GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        tags {
          Name 'geo_id'
        }
      }
      expect(res.remote_resource).to_not be_nil
      expect(res._terraform_id).to eq 't_id'
    end
  end

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_security_groups,
        {
          security_groups: [
            { group_name: 'name1', group_id: 'id1', tags: [{ key: 'Name', value: 'one' }] },
            { group_name: 'name2', group_id: 'id2', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_security_groups, stub)
      remote_resources = GeoEngineer::Resources::AwsSecurityGroup._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
