require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsIamPolicy") do
  common_resource_tests(GeoEngineer::Resources::AwsIamPolicy,
                        'aws_iam_policy')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      iam = AwsClients.iam
      # iam.list_policies.policies
      stub = iam.stub_data(
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
      sns.stub_responses(:list_policies, stub)
      remote_resources = GeoEngineer::Resources::AwsIamPolicy._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
