require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamInstanceProfile do
  let(:aws_client) { AwsClients.iam }

  before do
    aws_client.setup_stubbing
  end

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_instance_profiles,
        {
          instance_profiles:
          [
            {
              instance_profile_name: "test",
              instance_profile_id: "test",
              arn: "arn:aws:iam::1234567890:instance-profile/test",
              path: "/",
              create_date: Time.new,
              roles: []
            }
          ]
        }
      )
    end

    it 'should create list of profiles from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsIamInstanceProfile._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
