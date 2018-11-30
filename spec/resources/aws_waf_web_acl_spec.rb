require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsWafWebAcl) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:waf) { AwsClients.waf }
    before do
      stub = waf.stub_data(
        :list_web_acls,
        {
          web_acls: [
            {
              web_acl_id: 'name1',
              name: 'name1'
            },
            {
              web_acl_id: 'name2',
              name: 'name2'
            }
          ],
          next_marker: nil
        }
      )
      waf.stub_responses(:list_web_acls, stub)
    end

    after do
      waf.stub_responses(:list_web_acls, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsWafWebAcl._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
