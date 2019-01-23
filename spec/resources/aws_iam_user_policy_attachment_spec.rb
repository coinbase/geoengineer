require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamUserPolicyAttachment do
  let(:aws_client) { AwsClients.iam }
  common_resource_tests(described_class, described_class.type_from_class_name, false)

  let(:iam_policy) do
    GeoEngineer::Resources::AwsIamPolicy.new('aws_iam_policy', 'fake_policy') {
      name 'Fake-Aws-Policy'
    }
  end

  let(:iam_policy_attachment) do
    policy = iam_policy

    GeoEngineer::Resources::AwsIamPolicyAttachment
      .new('aws_iam_policy_attachment', 'fake_policy_attachment') {
        _policy policy
      }
  end

  describe '#remote_resource' do
    before do
      aws_client.stub_responses(
        :list_policies,
        {
          policies: [
            {
              arn: 'arn:aws:iam::aws:policy/xyv/FakeAwsARN',
              policy_name: 'Fake-Aws-Policy'
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
            { user_name: 'fake-policy' }
          ]
        }
      )
    end
  end
end
