require_relative '../spec_helper'

describe(GeoEngineer::Resources::PostgresqlSchema) do
  let(:postgres_results) { ['pg_catalog', 'public', 'test_schema'] }

  before do
    allow(PostgresqlClient).to receive(:database_schemas).and_return({})
  end

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      allow(PostgresqlClient).to receive(:database_schemas).and_return(postgres_results)
    end

    it 'should create list of hashes from returned postgres' do
      remote_resources = GeoEngineer::Resources::PostgresqlSchema._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 3
    end
  end
end
