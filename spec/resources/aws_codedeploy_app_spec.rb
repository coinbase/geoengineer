require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCodedeployApp do
  let(:aws_client) { AwsClients.codedeploy }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_applications,
        {
          applications: ["app1", "app2"]
        }
      )

      aws_client.stub_responses(
        :batch_get_applications,
        {
          applications_info: [
            {
              application_id: "app1_id",
              application_name: "app1"
            },
            {
              application_id: "app2_id",
              application_name: "app2"
            }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsCodedeployApp._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      res = resources.first

      expect(res[:_geo_id]).to eql("app1")
      expect(res[:_terraform_id]).to eql("app1_id:app1")
    end
  end
end
