########################################################################
# AwsLambdaAlias is the +aws_lambda_function+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lambda_alias.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLambdaAlias < GeoEngineer::Resource
  # Note: function_name here actually means function_arn, even though
  # function_name is also a key on a lambda function.
  validate -> { validate_required_attributes([:name, :function_name, :function_version]) }
  validate -> {
    if name && (name =~ /(?!^[0-9]+$)([a-zA-Z0-9\-_]+)/).nil?
      "#{name} must match: /(?!^[0-9]+$)([a-zA-Z0-9\-_]+)/"
    end
  }
  validate -> {
    if function_version && (function_version =~ /(\$LATEST|[0-9]+)/).nil?
      "#{function_version} must match: /(\$LATEST|[0-9]+)/"
    end
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { [name, function_name, function_version].join("::") } }

  def support_tags?
    false
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'function_name' => function_name,
      'name' => name
    }
    tfstate
  end

  # TODO(Brad) - May need to implement solution for pagination...
  def self._fetch_functions(provider)
    AwsClients
      .lambda(provider)
      .list_functions['functions']
      .map(&:to_h)
  end

  # TODO(Brad) - May need to implement solution for pagination...
  def self._fetch_aliases(provider, function)
    options = { function_name: function[:function_name] }
    AwsClients.lambda(provider).list_aliases(options)[:aliases].map(&:to_h).map do |f_alias|
      geo_id_components = [f_alias[:name], function[:function_arn], f_alias[:function_version]]
      f_alias.merge(
        {
          _terraform_id: f_alias[:alias_arn],
          _geo_id: geo_id_components.join('::')
        }
      )
    end
  end

  def self._fetch_remote_resources(provider)
    _fetch_functions(provider)
      .map { |function| _fetch_aliases(provider, function) }
      .flatten
      .compact
  end
end
