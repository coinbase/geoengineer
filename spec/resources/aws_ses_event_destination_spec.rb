require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSesEventDestination) do
  let(:ses_client) { AwsClients.ses }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { ses_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    before do
      ses_client.stub_responses(
        :list_configuration_sets,
        {
          configuration_sets: [
            {
              name: 'my-config-set'
            }
          ]
        }
      )

      ses_client.stub_responses(
        :describe_configuration_set,
        {
          configuration_set:
          {
            name: 'my-config-set',
          },
          event_destinations: [
            {
              name: 'a',
              matching_event_types: ["reject"]
            },
            {
              name: 'b',
              matching_event_types: ["reject"]
            }
          ]
        }
      )

    end

    it 'should create a list of event destinations from the AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsSesEventDestination._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
