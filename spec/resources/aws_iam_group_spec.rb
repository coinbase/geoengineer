require_relative '../spec_helper'

describe "GeoEngineer::Resource::AwsIamGroup" do
  common_resource_tests(GeoEngineer::Resources::AwsIamGroup, 'aws_iam_group')

  let(:aws_client) { AwsClients.iam }

  before { aws_client.setup_stubbing }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_groups, {
          groups: [
            {
              group_name: "Some-IAM-Group",
              group_id: "AAAAAAAAAAAAAAAAAAAAA",
              path: "/",
              arn: "arn:aws:iam::000000000000:group/Some-IAM-Group",
              create_date: Time.parse('2014-12-01T00:00:00Z')
            },
            {
              group_name: "Another-IAM-group",
              group_id: "AAAAAAAAAAAAAAAAAAAAA",
              path: "/",
              arn: "arn:aws:iam::000000000000:group/Another-IAM-group",
              create_date: Time.parse('2014-12-01T00:00:00Z')
            }
          ]
        }
      )
    end

    it 'should create a list of hashes returned AWS SDK' do
      resources = GeoEngineer::Resources::AwsIamGroup._fetch_remote_resources(nil)
      expect(resources.count).to eql(2)

      test_iam_group = resources.first
      expect(test_iam_group[:_terraform_id]).to eql("Some-IAM-Group")
      expect(test_iam_group[:_geo_id]).to eql("Some-IAM-Group")
    end
  end
end
