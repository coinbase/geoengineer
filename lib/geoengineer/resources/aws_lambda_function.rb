########################################################################
# AwsLambdaFunction is the +aws_lambda_function+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lambda_function.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLambdaFunction < GeoEngineer::Resource
  validate -> { validate_required_attributes([:function_name, :handler, :role]) }
  validate -> {
    if self.vpc_config
      validate_subresource_required_attributes(:vpc_config, [:subnet_ids, :security_group_ids])
    end
  }
  validate -> {
    if self.filename && (self.s3_bucket || self.s3_key || self.s3_object_version)
      ["Can only define filename OR S3 config, not both"]
    end
  }

  after :initialize, -> { _terraform_id -> { function_name } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'function_name' => function_name,
      'publish' => (publish || "false"),
      's3_bucket' => (s3_bucket || ""),
      's3_key' => (s3_key || "")
    }

    tfstate[:primary][:attributes]['filename'] = filename if filename

    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.lambda(provider).list_functions['functions'].map(&:to_h).map do |function|
      function.merge({ _terraform_id: function[:function_name] })
    end
  end
end
