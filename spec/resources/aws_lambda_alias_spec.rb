require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsLambdaAlias") do
  let(:aws_client) { AwsClients.lambda }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsLambdaAlias, 'aws_lambda_alias')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_functions, {
          functions: [
            { function_name: "foo", role: "arn:aws:iam:one", handler: "export.foo" },
            { function_name: "bar", role: "arn:aws:iam:two", handler: "export.bar" }
          ]
        }
      )
      aws_client.stub_responses(
        :list_aliases, {
          aliases: [
            { name: "foonew", alias_arn: "arn:aws:lambda:fooalias", function_version: "1" },
            { name: "barnew", alias_arn: "arn:aws:lambda:baralias", function_version: "2" }
          ]
        }
      )
    end

    after do
      aws_client.stub_responses(:list_functions, {})
      aws_client.stub_responses(:list_aliases, {})
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsLambdaAlias._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
