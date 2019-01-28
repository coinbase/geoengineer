require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSesConfigurationSet) do
  let(:ses_client) { AwsClients.ses }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { ses_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ses_client.stub_responses(
        :list_configuration_sets,
        {
          configuration_sets: [
            {
              name: 'my-config-set'
            },
            {
              name: 'my-config-set2'
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsSesConfigurationSet._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end