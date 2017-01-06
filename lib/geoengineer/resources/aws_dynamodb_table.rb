########################################################################
# AwsDynamodbTable +aws_dynamodb_table+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_dynamodb_table.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDynamodbTable < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :read_capacity, :write_capacity, :hash_key]) }

  after :initialize, -> { _terraform_id -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients.dynamo.list_tables['table_names'].map { |name|
      {
        name: name,
        _geo_id: name,
        _terraform_id: name
      }
    }
  end
end
