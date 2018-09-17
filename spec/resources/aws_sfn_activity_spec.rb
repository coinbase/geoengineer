require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSfnActivity) do
  let(:states) { AwsClients.states }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { states.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      states.stub_responses(
        :list_activities,
        {
          activities: [
            {
              name: 'FakeName',
              activity_arn: "arn1",
              creation_date: Time.now
            },
            {
              name: 'FakeName',
              activity_arn: "arn1",
              creation_date: Time.now
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsSfnActivity._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
