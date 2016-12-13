require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsIamRole" do
  let(:aws_client) { AwsClients.iam }

  common_resource_tests(GeoEngineer::Resources::AwsIamRole, 'aws_iam_role')

  before { aws_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_roles, { roles: [
          {
            role_name: 'Some-IAM-role',
            arn: "arn:aws:iam::123456789123:role/some-iam-role",
            path: "/",
            role_id: "XXXXXXXXXXXXXXXXXXXXY",
            create_date: Time.parse("2016-12-13 01:00:06 UTC"),
            assume_role_policy_document: ""
          },
          {
            role_name: 'Another-IAM-role',
            arn: "arn:aws:iam::123456789123:role/another-iam-role",
            path: "/",
            role_id: "XXXXXXXXXXXXXXXXXXXXY",
            create_date: Time.parse("2016-12-13 01:00:06 UTC"),
            assume_role_policy_document: ""
          }
        ] }
      )
    end

    it 'should create a list of hashes from the AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsIamRole._fetch_remote_resources
      expect(remote_resources.length).to eql 2

      test_role = remote_resources.first

      expect(test_role[:_terraform_id]).to eql('Some-IAM-role')
      expect(test_role[:_geo_id]).to eql('Some-IAM-role')
      expect(test_role[:name]).to eql('Some-IAM-role')
    end
  end
end
