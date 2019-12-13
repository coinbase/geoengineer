require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamRolePolicyAttachment do
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
            { role_name: 'fake-policy' }
          ]
        }
      )
    end
  end

  describe '#remote_resource_params' do
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
            { role_name: 'fake-role' }
          ]
        }
      )
    end

    it 'returns valid IDs for policies that exist' do
      pa = GeoEngineer::Resources::AwsIamRolePolicyAttachment.new('aws_iam_role_policy_attachment', 'fake_policy_attachment') {
        role 'fake-role'
        policy_arn 'arn:aws:iam::aws:policy/xyv/FakeAwsARN'
      }

      params = pa.remote_resource_params
      expect(params[:_terraform_id]).to eq "fake-role/arn:aws:iam::aws:policy/xyv/FakeAwsARN"
      expect(params[:_geo_id]).to eq "fake-role:arn:aws:iam::aws:policy/xyv/FakeAwsARN"
    end

    it 'returns nothing for Policy ARNs which do not exist yet' do
      aws_client.stub_responses(
        :list_entities_for_policy, 'NoSuchEntity'
      )

      pa = GeoEngineer::Resources::AwsIamRolePolicyAttachment.new('aws_iam_role_policy_attachment', 'fake_policy_attachment') {
        role 'fake-role'
        policy_arn 'arn:aws:iam::aws:policy/xyv/NewAwsARN'
      }

      params = pa.remote_resource_params
      expect(params).to eq({})
    end

    it 'returns nothing for Policy ARNs which are Terraform references' do
      pa = GeoEngineer::Resources::AwsIamRolePolicyAttachment.new('aws_iam_role_policy_attachment', 'fake_policy_attachment') {
        role 'fake-role'
        policy_arn '${aws_iam_policy.my_awesome_new_policy.arn}'
      }

      params = pa.remote_resource_params
      expect(params).to eq({})
    end
  end
end
