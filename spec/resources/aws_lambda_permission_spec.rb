require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLambdaPermission do
  let(:aws_client) { AwsClients.lambda }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsLambdaPermission, 'aws_lambda_permission')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_functions, {
          functions: [
            { function_name: "foo", role: "arn:aws:iam:one", handler: "export.foo", version: "1" },
            { function_name: "bar", role: "arn:aws:iam:two", handler: "export.bar", version: "1" }
          ]
        }
      )
      aws_client.stub_responses(
        :get_policy, {
          policy: { Statement: [{ Sid: Random.rand(1000).to_s }] }.to_json
        }
      )
    end

    after do
      aws_client.stub_responses(:list_functions, {})
      aws_client.stub_responses(:get_policy, {})
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsLambdaPermission._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end

  describe '#_parse_policy' do
    it "returns nil is there is a JSON Parse error" do
      expect(described_class._parse_policy("{ foo:  }")).to eq(nil)
    end

    context "with valid JSON" do
      it "returns a hash with symbols for keys" do
        policy = { foo: "bar", baz: ["qux"] }

        expect(described_class._parse_policy(policy.to_json)).to eq(policy)
        expect(described_class._parse_policy(policy.to_json).include?(:foo)).to eq(true)
      end
    end
  end

  describe '#_deep_symbolize_keys' do
    let(:simple_obj) { JSON.parse({ foo: "bar", baz: "qux" }.to_json) }
    let(:complex_obj) do
      JSON.parse(
        {
          foo: {
            bar: {
              baz: [
                { qux: "quack" }
              ]
            }
          },
          bar: [
            { foo: "bar" },
            nil,
            [{ baz: "qux" }],
            1,
            "baz"
          ]
        }.to_json
      )
    end

    it "converts top level keys to symbols" do
      expect(simple_obj.keys.include?(:foo)).to eq(false)
      expect(simple_obj.keys.include?("foo")).to eq(true)
      converted = described_class._deep_symbolize_keys(simple_obj)
      expect(converted.keys.include?(:foo)).to eq(true)
      expect(converted.keys.include?("foo")).to eq(false)
    end

    it "converts deeply nested keys to symbols" do
      converted = described_class._deep_symbolize_keys(complex_obj)
      expect(converted[:foo][:bar][:baz].first[:qux]).to eq("quack")
      expect(converted[:bar].first[:foo]).to eq("bar")
    end
  end
end
