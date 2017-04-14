require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamPolicy do
  let(:aws_client) { AwsClients.iam }

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

  common_resource_tests(described_class, described_class.type_from_class_name, false)

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

    context 'with a policy' do
      context 'when the policy does not have a remote resource' do
        before { expect(iam_policy_attachment).to receive(:remote_resource).and_return(nil) }

        it 'should not have a remote resource' do
          expect(iam_policy_attachment.remote_resource).to be_nil
        end
      end

      it 'should create a hash from the response' do
        remote_resource = iam_policy_attachment.remote_resource_params

        expect(remote_resource[:name]).to eql 'Fake-Aws-Policy'
        expect(remote_resource[:_terraform_id]).to eql 'arn:aws:iam::aws:policy/xyv/FakeAwsARN'
        expect(remote_resource[:_geo_id]).to eql 'Fake-Aws-Policy'

        expect(remote_resource[:users].length).to eql(2)
        expect(remote_resource[:groups].length).to eql(1)
        expect(remote_resource[:groups].length).to eql(1)
      end
    end
  end
end
