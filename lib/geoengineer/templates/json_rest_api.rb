# This template will create basic JSON REST API gateway resources
# It is recommended due to difficulties managing API_Gateway resources
# to use such a template
# This resource will also delete any resource on the API that is not defined
# within this template as a means of managing the resources
class GeoEngineer::Template::JsonRestApi < GeoEngineer::Template

  attr_reader :rest_api, :api_resources, :api_methods

  def initialize(name, project, params)
    super(name, project, params)

    # params
    # lambda:
    #   <ref>: lambda_resource
    # deployments:
    #   <name>: {} # TODO
    # resources:
    #   path:
    #   methods:
    #     <name>:
    #       method: <POST,PUT,GET...>
    #       authorization: <NONE,CUSTOM,AWS_IAM>
    #       handler: <lambda reference above>
    #

{
  lambda: {
    test: lambda_function
  },
  deployments:{
    prod: {}
  }
  methods: {
    create: {
      path: 'test',
      method: "POST",
      auth: "NONE",
      handler: :test # reference to lambda above
    }
  }
}

    ### Rest API
    rest_api = project.resource("aws_api_gateway_rest_api", "#{@name}_rest_api") {
      name @name
      # Depends on the lambda functions existing
      depends_on params[:lambda].values.map(&:terraform_name)
    }

    # Deployments
    for deployment_name, deployment_params in params[:deployments]
      project.resource("aws_api_gateway_deployment", "#{@name}_deployment_#{deployment_name}") {
        rest_api_id rest_api.to_ref
        stage_name deployment_name
      }
    end

    # Resources and Responses
    api_resources = {}
    for method_name, method_params in params[:methods]
      path = method_params[:path]

      api_resource = project.resource("aws_api_gateway_resource", "#{@name}_resource_#{path}") {
        rest_api_id rest_api.to_ref
        parent_id rest_api.to_ref("root_resource_id")
        path_part path
      }

      api_resources[path] = api_resource
    end

    # Methods
    api_methods = {}
    for method_name, method_params in params[:methods]
      path = method_params[:path]
      api_resource = api_resources[path]
      lambda_function = params[:lambda][method_params[:handler]]
      http_method = method_params[:method]

      method_name = "#{@name}_resource_#{path}_method_#{http_method}"

      api_method = project.resource("aws_api_gateway_method", method_name) {
        rest_api_id rest_api.to_ref
        resource_id api_resource.to_ref
        http_method http_method
        authorization method_params[:auth]
      }

      integration = project.resource("aws_api_gateway_integration", "#{method_name}_integration") {
        rest_api_id rest_api.to_ref
        resource_id api_resource.to_ref
        http_method api_method.to_ref("http_method")
        self["type"] = "AWS"
        integration_http_method api_method.to_ref("http_method")
        uri "arn:aws:apigateway:#{env.region}:lambda:path/2015-03-31/functions/#{lambda_function.to_ref('arn')}/invocations"
      }

      ### Response
      resp_200 = project.resource("aws_api_gateway_method_response", "200") {
        rest_api_id rest_api.to_ref
        resource_id api_resource.to_ref
        http_method api_method.to_ref("http_method")
        status_code "200"
        depends_on [integration.terraform_name]
      }

      project.resource("aws_api_gateway_integration_response", "#{@name}_integration_response") {
        rest_api_id rest_api.to_ref
        resource_id api_resource.to_ref
        http_method api_method.to_ref("http_method")
        status_code resp_200.to_ref("status_code")
        depends_on [integration.terraform_name]
      }

    end
  end

  def template_resources
    [@rest_api, @deployments, @resources]
  end
end

