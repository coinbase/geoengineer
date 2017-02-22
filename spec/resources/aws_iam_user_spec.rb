require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsIamUser") do
  let(:iam_client) { AwsClients.iam }

  common_resource_tests(GeoEngineer::Resources::AwsIamUser,
                        'aws_iam_user')

  before { iam_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      iam_client.stub_responses(
        :list_users,
        {
          users: [
            {
              user_name: 'FakeUser',
              user_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:user/FakeUser',
              path: '/',
              create_date: Time.parse('2016-03-23 16:33:32 UTC')
            },
            {
              user_name: 'FakeUser',
              user_id: 'ANTIPASTAAC2ZFSLA',
              arn: 'arn:aws:iam::123456789012:user/FakeUser',
              path: '/',
              create_date: Time.parse('2016-03-23 16:33:32 UTC')
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsIamUser._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
