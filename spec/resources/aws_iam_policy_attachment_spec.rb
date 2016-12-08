require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsIamPolicy" do
  let(:aws_client) { AwsClients.iam }
  common_resource_tests(GeoEngineer::Resources::AwsIamPolicyAttachment, 'aws_iam_policy_attachment')

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_policies,
        {
          policies: [
            {
              arn: 'arn:aws:iam::aws:policy/xyv/FakeAwsARN',
              policy_name: 'Fake-Aws-ARN'
            }
          ]
        }
      )

      aws_client.stub_responses(
        :list_entities_for_policy,
        {
          policy_users:  [
            { user_name: 'fake-user' },
            { user_name: 'fake-user-2' }
          ],
          policy_groups: [
            { group_name: 'fake-group' }
          ],
          policy_roles: [
            { role_name: 'fake-policy' }
          ]
        }
      )
    end

    it 'should create an array of hashes from the response' do
      resources = GeoEngineer::Resources::AwsIamPolicyAttachment._fetch_remote_resources
      expect(resources.count).to eql 1

      test_attachment = resources.first
      expect(test_attachment[:_terraform_id]).to eql('arn:aws:iam::aws:policy/xyv/FakeAwsARN')
      expect(test_attachment[:_geo_id]).to eql('Fake-Aws-ARN')
      expect(test_attachment[:users].count).to eql 2
      expect(test_attachment[:groups].count).to eql 1
      expect(test_attachment[:roles].count).to eql 1
    end
  end
end
