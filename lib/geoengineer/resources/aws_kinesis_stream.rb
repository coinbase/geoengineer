########################################################################
# AwsKinesisStream is the +aws_kinesis_stream+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_kinesis_stream.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsKinesisStream < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :shard_count]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> {
    _terraform_id -> {
      "arn:aws:kinesis:#{environment.region}:#{environment.account_id}:stream/#{self.name}"
    }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => self.name,
      'shard_count' => self.shard_count.to_s
    }
    tfstate
  end
end
