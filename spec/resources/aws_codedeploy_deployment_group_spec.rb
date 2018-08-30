require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCodedeployDeploymentGroup do
  let(:aws_client) { AwsClients.codedeploy }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_applications,
        {
          applications: ["app1"]
        }
      )

      aws_client.stub_responses(
        :list_deployment_groups,
        {
          deployment_groups: ["group1", "group2"]
        }
      )

      aws_client.stub_responses(
        :batch_get_deployment_groups,
        {
          deployment_groups_info: [
            {
              deployment_group_id: "group1_id",
              deployment_group_name: "group1"
            },
            {
              deployment_group_id: "group2_id",
              deployment_group_name: "group2"
            }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsCodedeployDeploymentGroup._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      res = resources.first

      expect(res[:_geo_id]).to eql("group1")
      expect(res[:_terraform_id]).to eql("group1_id")
    end
  end
end
