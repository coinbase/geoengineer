require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCodebuildProject do
  let(:aws_client) { AwsClients.codebuild }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  let(:project_name) { 'some-fake-project' }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_projects,
        {
          projects: [project_name]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsCodebuildProject._fetch_remote_resources(nil)
      expect(resources.count).to eql 1

      test_cloudproject = resources.first

      expect(test_cloudproject[:name]).to eql(project_name)
      expect(test_cloudproject[:_geo_id]).to eql(project_name)
      expect(test_cloudproject[:_terraform_id]).to eql(project_name)
    end
  end
end
