################################################################################
# PostgresqlDatabase is the postgresql_database+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/postgresql/r/postgresql_database.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::PostgresqlDatabase < GeoEngineer::Resource
  #validate -> { validate_required_attributes([:team_id, :repository]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{name}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    database_names = PostgresClient.database_names(provider)
    databases = []
    database_names.each do |row|
      databases << { _terraform_id: row['datname']}
    end

    return databases
  end
end
