require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamRolePolicy do
  let(:iam_client) { AwsClients.iam }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { iam_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      iam_client.stub_responses(
        :list_roles,
        {
          roles: [
            {
              role_name: 'Some-IAM-role',
              arn: "arn:aws:iam::123456789123:role/some-iam-role",
              path: "/",
              role_id: "XXXXXXXXXXXXXXXXXXXXY",
              create_date: Time.parse("2016-12-13 01:00:06 UTC"),
              assume_role_policy_document: ""
            }
          ]
        }
      )
      iam_client.stub_responses(
        :list_role_policies,
        {
          policy_names: ["Some-Policy-Name"],
          is_truncated: false
        }
      )
      iam_client.stub_responses(
        :get_role_policy,
        {
          role_name: 'Some-IAM-role',
          policy_name: 'Some-Policy-Name',
          policy_document: "{ Some Policy Here... }"
        }
      )
      remote_resources = GeoEngineer::Resources::AwsIamRolePolicy._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
