# This template will create basic JSON REST API gateway resources
# It is recommended due to difficulties managing API_Gateway resources
# to use such a template
# This resource will also delete any resource on the API that is not defined
# within this template as a means of managing the resources
class GeoEngineer::Templates::JsonRestApi < GeoEngineer::Template
  attr_reader :rest_api, :api_resources, :api_methods

  def initialize(name, project, params)
    super(name, project, params)

    # parameters
    # lambda:
    #   <ref>: lambda_resource
    # deployments:
    #   <name>: {} # TODO
    # methods:
    #   <name>:
    #     path:
    #     method: <POST,PUT,GET...>
    #     authorization: <NONE,CUSTOM,AWS_IAM>
    #     handler: <lambda ref>
    #

    ### Rest API
    rest_api = project.resource("aws_api_gateway_rest_api", "#{@name}_rest_api") {
      name name
      # Depends on the lambda functions existing
      depends_on params[:lambda].values.map(&:terraform_name)
    }

    # Resources and Responses
    api_resources = {}
    for method_name, method_params in params[:methods]
      path = method_params[:path]
      next if api_resources[path]

      api_resource = project.resource("aws_api_gateway_resource", "#{@name}_resource_#{path}") {
        _rest_api rest_api
        path_part path
      }

      api_resources[path] = api_resource
    end

    # Methods
    api_methods = {}
    api_integrations = {}
    api_method_responses = {}
    api_integration_responses = {}
    for method_name, method_params in params[:methods]
      path = method_params[:path]
      api_resource = api_resources[path]
      lambda_function = params[:lambda][method_params[:handler]]
      http_method = method_params[:method]

      method_name = "#{@name}_resource_#{path}_method_#{http_method}"

      # METHOD
      api_method = project.resource("aws_api_gateway_method", method_name) {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        authorization method_params[:auth]
      }

      # INTEGRATION
      api_integration = project.resource("aws_api_gateway_integration", "#{method_name}_integration") {
        _rest_api rest_api
        _resource api_resource
        http_method http_method
        self["type"] = "AWS"
        integration_http_method http_method
        uri "arn:aws:apigateway:#{env.region}:lambda:path/2015-03-31/functions/#{lambda_function.to_ref('arn')}/invocations"
      }

      api_methods[method_name] = api_method
      api_integrations[method_name] = api_integration

      # RESPONSES
      api_method_responses[method_name] = []
      api_integration_responses[method_name] = []

      responses = ["200"]
      for resp in responses
        api_method_response = project.resource("aws_api_gateway_method_response", "#{method_name}_200") {
          _rest_api rest_api
          _resource api_resource
          http_method http_method
          status_code resp
          depends_on [api_method, api_integration].map(&:terraform_name)
        }

        api_integration_response = project.resource("aws_api_gateway_integration_response", "#{method_name}_200_integration_response") {
          _rest_api rest_api
          _resource api_resource
          http_method http_method
          status_code resp
          depends_on [api_method, api_integration].map(&:terraform_name)
        }

        api_method_responses[method_name] << api_method_response
        api_integration_responses[method_name] << api_integration_response
      end
    end

    # Deployments
    api_deployments = {}
    for deployment_name, deployment_params in params[:deployments]
      api_deployment = project.resource("aws_api_gateway_deployment", "#{@name}_deployment_#{deployment_name}") {
        _rest_api rest_api
        depends_on api_methods.values.map(&:terraform_name)
        stage_name deployment_name
      }
      api_deployments[deployment_name] = api_deployment
    end

    # TODO: delete uncodified resources
    rest_api.delete_uncodified_children_resoures
    @rest_api = rest_api
  end

  def template_resources
    [@rest_api, @deployments, @resources]
  end
end
