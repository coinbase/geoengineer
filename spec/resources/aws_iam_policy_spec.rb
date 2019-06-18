require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamPolicy do
  let(:iam_client) { AwsClients.iam }

  common_resource_tests(described_class, described_class.type_from_class_name)
  before { iam_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      iam_client.stub_responses(
        :list_policies,
        {
          policies: [
            {
              policy_name: 'FakePolicy',
              policy_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:policy/FakePolicy',
              path: '/'
            },
            {
              policy_name: 'FakePolicy',
              policy_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:policy/FakePolicy',
              path: '/'
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsIamPolicy._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end

  describe "#validate_resources_not_empty" do
    it "ensures that no policy has statements without a valid Resource or NotResource field" do
      invalid1 = GeoEngineer::Resources::AwsIamPolicy.new('subject', 'id') {
        name('foo')
        policy('{"Version": "2012-10-17", "Statement":
               [{"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"], "Resource": []}]}')
      }
      expect(invalid1.errors.length).to be 1

      invalid2 = GeoEngineer::Resources::AwsIamPolicy.new('subject', 'id') {
        name('foo')
        policy('{"Version": "2012-10-17", "Statement":
               [{"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"], "NotResource": []}]}')
      }
      expect(invalid2.errors.length).to be 1

      invalid3 = GeoEngineer::Resources::AwsIamPolicy.new('subject', 'id') {
        name('foo')
        policy('{"Version": "2012-10-17", "Statement":
               [{"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"]}]}')
      }
      expect(invalid3.errors.length).to be 1

      invalid4 = GeoEngineer::Resources::AwsIamPolicy.new('subject', 'id') {
        name('foo')
        policy('{"Version": "2012-10-17", "Statement":
               [{"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"], "Resource": "*"},
               {"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"], "Resource": []}]}')
      }
      expect(invalid4.errors.length).to be 1

      valid = GeoEngineer::Resources::AwsIamPolicy.new('subject', 'id') {
        name('foo')
        policy('{"Version": "2012-10-17", "Statement":
               [{"Effect": "Allow", "Action": ["autoscaling:DescribeAutoScalingInstances"], "Resource": "*"}]}')
      }
      expect(valid.errors).to be_empty
    end
  end
end
