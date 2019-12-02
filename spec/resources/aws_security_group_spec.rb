require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSecurityGroup) do
  common_resource_tests(described_class, described_class.type_from_class_name)
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

    it 'fails when protocol is -1 but ports other than 0 are specified' do
      expect(GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          protocol '-1'
          to_port 53
          from_port 53
          cidr_blocks ['0.0.0.0/0']
        }
      }.errors.grep(/Cannot specify protocol of -1/i).size).to eq 1

      expect(GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          protocol '-1'
          to_port 0
          from_port 0
          cidr_blocks ['0.0.0.0/0']
        }
      }.errors.grep(/Cannot specify protocol of -1/i).size).to eq 0
    end

    it 'fails when rules do not specify a src/dest' do
      expect(GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          to_port 80
          from_port 80
        }
      }.errors.grep(/rules must specify at least one source/i).size).to eq 1

      expect(GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          to_port 80
          from_port 80
          cidr_blocks ['0.0.0.0/0']
        }
      }.errors.grep(/rules must specify at least one source/i).size).to eq 0

      expect(GeoEngineer::Resources::AwsSecurityGroup.new('type', 'id') {
        ingress {
          to_port 80
          from_port 80
          self['self'] = true
        }
      }.errors.grep(/rules must specify at least one source/i).size).to eq 0
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
    let(:ec2) { AwsClients.ec2 }
    before do
      ec2.stub_responses(:describe_security_groups, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
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
      remote_resources = GeoEngineer::Resources::AwsSecurityGroup._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end

    it 'works if remote resources have no tags' do
      stub = ec2.stub_data(
        :describe_security_groups,
        {
          security_groups: [
            { group_name: 'name1', group_id: 'id1' },
            { group_name: 'name2', group_id: 'id2' }
          ]
        }
      )
      ec2.stub_responses(:describe_security_groups, stub)
      remote_resources = GeoEngineer::Resources::AwsSecurityGroup._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end

    it 'works if remote resources have tags with Name' do
      stub = ec2.stub_data(
        :describe_security_groups,
        {
          security_groups: [
            { group_name: 'name1', group_id: 'id1', tags: [{ key: 'Foo', value: 'one' }] },
            { group_name: 'name2', group_id: 'id2', tags: [{ key: 'Bar', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_security_groups, stub)
      remote_resources = GeoEngineer::Resources::AwsSecurityGroup._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
