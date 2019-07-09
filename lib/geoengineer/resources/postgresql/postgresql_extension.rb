################################################################################
# PostgresqlExtension is the postgresql_extension+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/postgresql/r/postgresql_extension.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::PostgresqlExtension < GeoEngineer::Resource

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{name}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    database_extensions = PostgresClient.database_extensions(provider)
    database_extensions.map { |extension| { _terraform_id: extension }}
  end
end
