require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsIamUser") do
  common_resource_tests(GeoEngineer::Resources::AwsIamUser,
                        'aws_iam_user')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      iam = AwsClients.iam
      # iam.list_policies.policies
      stub = iam.stub_data(
        :list_users,
        {
          users: [
            {
              user_name: 'FakeUser',
              user_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:user/FakeUser',
              path: '/'
            },
            {
              user_name: 'FakeUser',
              user_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:user/FakeUser',
              path: '/'
            }
          ]
        }
      )
      sns.stub_responses(:list_users, stub)
      remote_resources = GeoEngineer::Resources::AwsIamUser._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
