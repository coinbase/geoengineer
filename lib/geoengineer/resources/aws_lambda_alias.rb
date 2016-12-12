########################################################################
# AwsLambdaAlias is the +aws_lambda_function+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lambda_alias.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLambdaAlias < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :function_name, :function_version]) }
  validate -> {
    !(name =~ /(?!^[0-9]+$)([a-zA-Z0-9\-_]+)/).nil? if name
  }
  validate -> {
    !(function_version =~ /(\$LATEST|[0-9]+)/).nil? if function_version
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { [name, function_name, function_version].join("::") } }

  def support_tags?
    false
  end

  # TODO(Brad) - May need to implement solution for pagination...
  def self._fetch_functions
    AwsClients
      .lambda
      .list_functions['functions']
      .map(&:to_h)
  end

  # TODO(Brad) - May need to implement solution for pagination...
  def self._fetch_aliases(function)
    options = { function_name: function[:function_name] }
    AwsClients.lambda.list_aliases(options)[:aliases].map(&:to_h).map do |f_alias|
      geo_id_components = [f_alias[:name], f_alias[:function_name], f_alias[:function_version]]
      f_alias.merge(
        {
          _terraform_id: f_alias[:alias_arn],
          _geo_id: geo_id_components.join('::')
        }
      )
    end
  end

  def self._fetch_remote_resources
    _fetch_functions
      .map { |function| _fetch_aliases(function) }
      .flatten
      .compact
  end
end
