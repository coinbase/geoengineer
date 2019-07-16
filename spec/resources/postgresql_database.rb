require_relative '../spec_helper'

describe(GeoEngineer::Resources::PostgresqlDatabase) do
  let(:postgres_results) { ['testdb', 'testdb2', 'template0'] }

  before do
    allow(PostgresqlClient).to receive(:database_names).and_return({})
  end

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      allow(PostgresqlClient).to receive(:database_names).and_return(postgres_results)
    end

    it 'should create list of hashes from returned postgres' do
      remote_resources = GeoEngineer::Resources::PostgresqlDatabase._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 3
    end
  end
end
