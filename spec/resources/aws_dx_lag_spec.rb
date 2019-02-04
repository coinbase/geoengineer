require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsDxLag) do
  let(:aws_client) { AwsClients.directconnect }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_lags,
        {
          lags: [
            { lag_id: 'id1', lag_name: 'name1' },
            { lag_id: 'id2', lag_name: 'name2' }
          ]
        }
      )
    end

    after do
      aws_client.stub_responses(:describe_lags, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsDxLag._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
