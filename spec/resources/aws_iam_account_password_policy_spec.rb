require_relative '../spec_helper'

describe 'GeoEngineer::Resources::AwsIamAccountPasswordPolicy' do
  let(:aws_client) { AwsClients.iam }

  before { aws_client.setup_stubbing }

  let(:iam_password_policy) do
    GeoEngineer::Resources::AwsIamAccountPasswordPolicy
      .new('aws_iam_account_password_policy', 'fake_password_policy') {
        allow_users_to_change_password true
      }
  end

  common_resource_tests(
    GeoEngineer::Resources::AwsIamAccountPasswordPolicy,
    'aws_iam_account_password_policy',
    false
  )

  let(:password_policy_params) do
    { require_symbols: true,
      require_numbers: true,
      require_uppercase_characters: true,
      require_lowercase_characters: true,
      allow_users_to_change_password: true,
      expire_passwords: true,
      max_password_age: 365,
      password_reuse_prevention: 6 }
  end

  describe '#remote_resource_params' do
    before do
      aws_client.stub_responses(
        :get_account_password_policy,
        {
          password_policy: password_policy_params
        }
      )
    end

    it 'should create a hash from the remote resource' do
      singleton_id = GeoEngineer::Resources::AwsIamAccountPasswordPolicy::SINGLETON_ID

      expected_params = password_policy_params.merge({ _geo_id: singleton_id,
                                                       _terraform_id: singleton_id })

      expect(iam_password_policy.remote_resource_params).to eql(expected_params)
    end
  end
end
