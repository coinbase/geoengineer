########################################################################
# AwsDynamodbTable +aws_dynamodb_table+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_dynamodb_table.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDynamodbTable < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :hash_key]) }

  after :initialize, -> { _terraform_id -> { name } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    return tfstate unless self.ttl

    tfstate[:primary][:attributes] = {
      "ttl.#" => "1",
      # random number determined by fair dice roll, used to flatten list to hash
      "ttl.0000000006.attribute_name": ttl.attribute_name.to_s,
      "ttl.0000000006.enabled": ttl.enabled.to_s
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    AwsClients.dynamo(provider).list_tables['table_names'].map { |name|
      {
        name: name,
        _geo_id: name,
        _terraform_id: name
      }
    }
  end
end
