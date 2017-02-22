require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsIamPolicy" do
  let(:iam_client) { AwsClients.iam }

  common_resource_tests(GeoEngineer::Resources::AwsIamPolicy,
                        'aws_iam_policy')

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
end
