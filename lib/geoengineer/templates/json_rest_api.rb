# This template will create basic JSON REST API gateway resources
# It is recommended due to difficulties managing API_Gateway resources
# to use such a template
# This resource will also delete any resource on the API that is not defined
# within this template as a means of managing the resources
# Beta Template
class GeoEngineer::Templates::JsonRestApi < GeoEngineer::Template
  attr_reader :rest_api

  def create_rest_resources(params)
    rest_api = @rest_api
    api_resources = {}
    params[:methods].each do |method_name, method_params|
      path = method_params[:path]
      next if api_resources[path]

      api_resource = parent.resource("aws_api_gateway_resource", "#{@name}_resource_#{path}") {
        _rest_api rest_api
        path_part path
      }

      api_resources[path] = api_resource
    end
    api_resources
  end

  def create_rest_methods(api_resources, params)
    rest_api = @rest_api
    api_methods = {}
    params[:methods].each do |method_name, method_params|
      path = method_params[:path]
      api_resource = api_resources[path]
      http_method = method_params[:method]

      method_name = "#{@name}_resource_#{path}_method_#{http_method}"

      # METHOD
      api_methods[method_name] = parent.resource("aws_api_gateway_method", method_name) {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        authorization method_params[:auth]
        api_key_required !!method_params[:api_key]
      }
    end

    api_methods
  end

  def create_rest_integrations(api_resources, params)
    rest_api = @rest_api
    api_integrations = {}
    params[:methods].each do |method_name, method_params|
      path = method_params[:path]
      api_resource = api_resources[path]
      lambda_function = params[:lambda][method_params[:handler]]
      http_method = method_params[:method]

      method_name = "#{@name}_resource_#{path}_method_#{http_method}"

      api_gateway_arn = "arn:aws:apigateway:#{env.region}"
      invocation_arn = "functions/#{lambda_function.to_ref('arn')}/invocations"
      # INTEGRATION
      api_integrations[method_name] = parent.resource(
        "aws_api_gateway_integration",
        "#{method_name}_integration"
      ) {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        self["type"] = "AWS"
        integration_http_method "POST" # ALWAYS POST TO LAMBDAS
        uri "#{api_gateway_arn}:lambda:path/2015-03-31/#{invocation_arn}"
      }
    end
    api_integrations
  end

  def http_method_response_mappings(api_resources, params)
    https_methods = params[:methods].values.map { |m| m[:method] }.uniq

    response_mappings = {}
    https_methods.each do |m|
      response_mappings["#{m}_success"] = {
        status: "200",
        method: m
      }

      response_mappings["#{m}_notfound"] = {
        status: "404",
        method: m,
        selection_pattern: ".*NotFound.*"
      }
    end

    api_resources.values.each do |api_resource|
      response_mappings.each do |name, mapping|
        yield api_resource, name, mapping
      end
    end
  end

  def create_api_methods_responses(api_resources, api_methods, params)
    rest_api = @rest_api
    api_method_responses = []

    http_method_response_mappings(api_resources, params) do |api_resource, name, mapping|
      http_method = mapping[:method]
      status = mapping[:status]

      api_method_response = parent.resource(
        "aws_api_gateway_method_response",
        "mr_#{api_resource.id}_#{name}"
      ) {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        status_code status
        depends_on [api_methods.values].flatten.map(&:terraform_name)
        depends_on api_method_responses.map(&:terraform_name) # force order
      }

      api_method_responses << api_method_response
    end

    api_method_responses
  end

  def create_api_integrations_responses(api_resources, api_integrations, params)
    rest_api = @rest_api
    api_integration_responses = []

    http_method_response_mappings(api_resources, params) do |api_resource, name, mapping|
      http_method = mapping[:method]
      status = mapping[:status]
      selection_pattern = mapping[:selection_pattern]

      api_integration_response = parent.resource(
        "aws_api_gateway_integration_response",
        "ir_#{api_resource.id}_#{name}"
      ) {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        status_code status
        selection_pattern selection_pattern if selection_pattern
        depends_on [api_integrations.values].flatten.map(&:terraform_name)
        depends_on api_integration_responses.map(&:terraform_name) # force order
      }

      api_integration_responses << api_integration_response
    end

    api_integration_responses
  end

  attr_reader :rest_api

  def initialize(name, parent, params)
    super(name, parent, params)

    # parameters
    # lambda:
    #   <ref>: lambda_resource
    # methods:
    #   <name>:
    #     path:
    #     method: <POST,PUT,GET...>
    #     auth: <NONE,CUSTOM,AWS_IAM>
    #     api_key: <false>
    #     handler: <lambda ref>
    #

    ### Rest API
    @rest_api = parent.resource("aws_api_gateway_rest_api", "#{@name}_rest_api") {
      name name
      # Depends on the lambda functions existing
      depends_on params[:lambda].values.map(&:terraform_name)
    }

    # Resources and Responses
    api_resources = create_rest_resources(params)

    api_methods = create_rest_methods(api_resources, params)
    api_integrations = create_rest_integrations(api_resources, params)

    # RESPONSES
    create_api_methods_responses(api_resources, api_methods, params)
    create_api_integrations_responses(api_resources, api_integrations, params)

    # TODO: delete uncodified resources
  end

  def template_resources
    @rest_api
  end
end
