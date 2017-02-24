require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsLambdaFunction") do
  let(:aws_client) { AwsClients.lambda }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsLambdaFunction, 'aws_lambda_function')

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_functions, {
          functions: [
            { function_name: "foo", role: "arn:aws:iam:one", handler: "export.foo" },
            { function_name: "bar", role: "arn:aws:iam:two", handler: "export.bar" }
          ]
        }
      )
    end

    after { aws_client.stub_responses(:list_functions, {}) }

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsLambdaFunction._fetch_remote_resources(nil)
      expect(resources.count).to eql(2)
    end
  end
end
