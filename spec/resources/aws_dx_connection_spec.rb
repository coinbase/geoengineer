require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsDxConnection) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      directconnect = AwsClients.directconnect
      stub = directconnect.stub_data(
        :describe_connections,
        {
          connections: [
            { connection_id: 'name1', bandwidth: "10Gbps", location: "EqDC2" },
            { connection_id: 'name2', bandwidth: "10Gbps", location: "EqDC2" }
          ]
        }
      )
      directconnect.stub_responses(:describe_connections, stub)
      remote_resources = GeoEngineer::Resources::AwsDxConnection._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
