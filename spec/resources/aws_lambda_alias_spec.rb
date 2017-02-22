require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLambdaAlias do
  let(:aws_client) { AwsClients.lambda }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsLambdaAlias, 'aws_lambda_alias')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_functions, {
          functions: [
            {
              function_name: "foo",
              function_arn: "arn:aws:lambda:us-east-1:123:function:foo",
              role: "arn:aws:iam:one",
              handler: "export.foo"
            },
            {
              function_name: "bar",
              function_arn: "arn:aws:lambda:us-east-1:123:function:bar",
              role: "arn:aws:iam:two",
              handler: "export.bar"
            }
          ]
        }
      )
      aws_client.stub_responses(
        :list_aliases, {
          aliases: [
            { name: "foonew", alias_arn: "arn:aws:lambda:alias", function_version: "1" }
          ]
        }
      )
    end

    after do
      aws_client.stub_responses(:list_functions, {})
      aws_client.stub_responses(:list_aliases, {})
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsLambdaAlias._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end

    it 'should match a local resource to the remote resource' do
      subject = described_class.new('aws_lambda_alias', 'foo') {
        name "foonew"
        function_name "arn:aws:lambda:us-east-1:123:function:foo"
        function_version 1
      }
      expect(subject.remote_resource).to_not be_nil
    end
  end
end
