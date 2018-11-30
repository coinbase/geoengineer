require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsWafRule) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:waf) { AwsClients.waf }
    before do
      stub = waf.stub_data(
        :list_rules,
        {
          rules: [
            {
              rule_id: 'name1',
              name: 'name1'
            },
            {
              rule_id: 'name2',
              name: 'name2'
            }
          ],
          next_marker: nil
        }
      )
      waf.stub_responses(:list_rules, stub)
    end

    after do
      waf.stub_responses(:list_rules, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsWafRule._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
