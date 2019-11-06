# GeoEngineer

[![CircleCI](https://circleci.com/gh/coinbase/geoengineer.svg?style=shield)](https://circleci.com/gh/coinbase/geoengineer)

<a href="https://commons.wikimedia.org/wiki/File:Mantle_of_Responsibility.png"><img src="./assets/mantle.png" align="right" alt="Mantle_of_Responsibility" /></a>

GeoEngineer provides a Ruby DSL and command line tool (`geo`) to *codify*  then plan and execute changes to cloud resources.

GeoEngineer's goals/requirements/features are:

0. **DSL based on Terraform**: GeoEngineer uses [Terraform](https://github.com/hashicorp/terraform) to plan and execute changes, so the DSL to describe resources is similar to Terraform's. GeoEngineer's DSL also provides programming and object oriented features like inheritance, abstraction, branching and looping.
1. **Development Workflow**: GeoEngineer is built to be used within existing development workflows, e.g. branching, creating pull requests, code reviewing and merging. To simplify these workflows, GeoEngineer dynamically generates Terraform state files using cloud APIs and opinionated tagging.
2. **Extensible Validation**: Every team has their own standards when managing cloud resources e.g. naming patterns, tagging requirements, security rules. GeoEngineer resources can have custom validations added to ensure the resources conform to required standards.
3. **Describe Existing Resources**: Existing resources can be described with GeoEngineer without having to destroy and recreate them.
4. **Principle of Least Astonishment**: show the exact plan before execution; do nothing without confirmation; do not allow a plan to be executed with failing validations; by default do not allow deletions; show warnings and hints to make code better.
5. **One File per Project**: Managing dozens of projects with hundreds of files is difficult and error-prone, especially if a single project's resources are described across many files. Projects are easier to manage when they are each described in one file.
6. **Dependencies**: resources have dependencies on other resources, projects have dependencies on other projects. Using Ruby's `require` file that describe resources can be included and referenced without having to hard-code any values.

## Getting Started

### Install Terraform

Instructions to install Terraform can be found [here](https://www.terraform.io/downloads.html).

    brew install terraform

### Install Ruby

Instructions to install Ruby can be found [here](https://www.ruby-lang.org/en/documentation/installation/).

    rbenv install `cat .ruby-version`

### Install GeoEngineer

Build the gem locally and then refer to it with `geo` on the command line.

    bundle install
    gem build geoengineer.gemspec
    gem install geoengineer-version.gem
    geo --help

### Running GeoEngineer

Install and configure [`assume-role`](https://github.com/coinbase/assume-role).

    assume-role <account-id> <role>
    ./geo --help

### First GeoEngineer Project

GeoEngineer can use the folder structure where projects and environments are in the `projects` and `environments` directories respectively, however everything can also be defined in a single file, e.g. `first_project.rb`:

```ruby
# First define the environment which is available with the variable `env`
# This is where project invariants are stored, e.g. subnets, vpc ...
environment("staging") {
  account_id  "1"
  subnet      "1"
  vpc_id      "1"
  allow_destroy true ## Defaults to false.  Set to true to support `geo destroy ...`
}

# Create the first_project to be in the `staging` environment
project = project('org', 'first_project') {
  environments 'staging'
}

# Define the security group for the ELB to allow HTTP
elb_sg = project.resource("aws_security_group", "allow_http") {
  name         "allow_http"
  description  "Allow All HTTP"
  vpc_id       env.vpc_id
  ingress {
      from_port    80
      to_port      80
      protocol     "tcp"
      cidr_blocks  ["0.0.0.0/0"]
  }
  tags {
    Name "allow_http"
  }
}

# Define the security group for EC2 to allow ingress from the ELB
ec2_sg = project.resource("aws_security_group", "allow_elb") {
  name         "allow_elb"
  description  "Allow ELB to 80"
  vpc_id       env.vpc_id
  ingress {
      from_port    8000
      to_port      8000
      protocol     "tcp"
      security_groups  [elb_sg]
  }
  tags {
    Name "allow_elb"
  }
}

# cloud_config to run webserver
user_data = %{
#cloud-config
runcmd:
  - docker run -d --name nginx -p 8000:80 nginx
}

# Create an EC2 instance to run nginx server
instance = project.resource("aws_instance", "web") {
  ami           "ami-1c94e10b" # COREOS AMI
  instance_type "t1.micro"
  subnet_id     env.subnet
  user_data     user_data
  tags {
    Name "ec2_instance"
  }
}

# Create the ELB connected to the instance
project.resource("aws_elb", "main-web-app") {
  name             "main-app-elb"
  security_groups  [elb_sg]
  subnets          [env.subnet]
  instances        [instance]
  listener {
    instance_port     8000
    instance_protocol "http"
    lb_port           80
    lb_protocol       "http"
  }
}
```

The GeoEngineer command line tool `geo` can:

1. **Create a plan** with `geo plan -e staging first_project.rb`
2. **Execute the plan** with `geo apply -e staging first_project.rb`
3. **Create a graph** with `geo graph -e staging --quiet first_project.rb | dot -Tpng > graph.png && open graph.png`
4. **Status of Codified Resources** with `geo status first_project.rb -e staging`
5. **Query GPS Resource Graph** with `geo query "*:*:*:*:*"`

*There are more examples in the `examples` folder.*

## Customizations

GeoEngineer's DSL can be customized to your needs using validations, GPS and reusable methods on resources.

### Validations

Below is an example which will add the validation to ensure that all listeners on all ELB's must be HTTPS, for security reasons.

```ruby
class GeoEngineer::Resources::AwsElb < GeoEngineer::Resource
  validate :validate_listeners_must_be_https

  def validate_listeners_must_be_https
    errors = []
    all_listener.select{ |i| i.lb_protocol != 'https' }.each do
      errors << "ELB must use https protocol #{for_resource}"
    end
    return errors
  end
end
```

### Geo Planning System (GPS)

GeoEngineer describes resources in the **cloud** domain, not **your** application domain. For example, security group ingress is the "cloud" way of defining "what can call your service". The friction between these two domains makes communication with others (e.g. developers) difficult.

GPS is an abstraction that helps you describe your cloud in the language of your domain. GPS:

1. **Uses Higher Level Vocabulary** to build configurations.
1. **Explicit Configurations** means no tricks; What you see is what you get.
1. **YAML and JSON Schema** to strictly configure using known standards.
1. **Extensible Configuration** lets GPS express any domain.
1. **Backwards Compatible**: GPS is built to work with current GeoEngineer resources.

GPS files look like `gps/org/first-project.yml`:

```yml
<environment>:
  <configuration>:
    <node_type>:
      <node_name>:
        <attributes>:
```

The filename is used to define the project. The `environment` and `configuration` are used to group nodes. Each configuration has multiple nodes, defined under their types. You can define your own node types that can allow multiple `attributes`.

For example, the file `./gps/org/first-project.yml` describes a node `service` named `api` with configuration `staging` in the `development` environment:

```yml
development:
  staging:
    service:
      api:
        ports: "80:80"
```

If you have multiple environments and wish something to be applied to all of them evenly, you can use `_default` as a special environment keyword. This will be applied to all known environments, unless they are already defined. For example, if you had a project that was deployed to all environments except one named `internal`, you could use the following example:

```yml
_default:
  common:
    service:
      api:
        ports: "80:80"
internal: {}
```

The `service` node type is defined to take a string of ports and build a Load balancer:

```ruby
# Load Balancer Node
class GeoEngineer::GPS::Nodes::Service < GeoEngineer::GPS::Node
  # explicity define the exposed resources from this node
  define_resource "aws_elb", :elb

  # define the types of attributes using JSON schema
  def json_schema
    {
      "type":  "object",
      "additionalProperties" => false,
      "properties":  {
        "ports":  {
          "type":  "string",
          "default":  "80:80"
        }
      }
    }
  end

  # called by GPS when creating resources
  def create_resources(project)
    create_elb(project) # method created with `define_resource`
    setup_elb
  end

  def setup_elb
    # Set the values of the resource here
    elb.ports = attributes["ports"]
  end
end
```

To integrate with a project use:

```ruby
project = gps.project("org", "first-project", env) do |nodes|
  # query for api filling in the default env, config, project...
  nodes.find(":::service:api")
end

# Find the service
# query syntax is `<project>:<environment>:<config>:<type>:<name>`
service = gps.find("org/first-project:development:staging:service:api")

# method to get the GeoEngineer resource ELB
service.elb

# method to get the terraform reference to the resource
service.elb_ref

# return all service nodes
gps.where("org/first-project:*:*:service:*").each do |node|
  node.elb.tags { ... }
end
```

### Methods

Define methods to be used in your own resources, e.g. a custom method to security group to add a rule:

```ruby
class GeoEngineer::Resources::AwsSecurityGroup < GeoEngineer::Resource
  # ...
  def all_egress_everywhere
    egress {
        from_port        0
        to_port          0
        protocol         "-1"
        cidr_blocks      ["0.0.0.0/0"]
    }
  end
  # ...
end

project.resource('aws_security_group', 'all_egress') {
  all_egress_everywhere # use the method to add egress
}
```

## Adding New Resources

The best way to contribute is to add resources that exist in Terraform but are not yet described in GeoEngineer.

To define a resource:

0. checkout and fork/branch GeoEngineer
1. create a file `./lib/geoengineer/resources/<provider_type>/<resource_type>.rb`
2. define a class `class GeoEngineer::Resources::<ResourceType> < GeoEngineer::Resource`
3. define `_terraform_id`, and potentially `_geo_id` and `self._fetch_remote_resources` method (more below).
4. write a test file for the resource that follows the style of other similar resources

### Codified to Remote Resources

A fundamental problem with codifying resources is matching the in code resource to the real remote resource. Terraform does this by maintaining an `id` in a state file which is matched to a remote resources attribute. This attribute is different per resource, e.g. for ELB's it is their `name`, for security groups it is their `group_name` that is generated so cannot be codified.

Without a state file GeoEngineer uses API's to match resources, this makes generated `id`'s likes security groups difficult. For these generated ids GeoEngineer uses tags e.g. for ELB's the GeoEngineer id is its `name` (just like Terraform) and for security groups it is their `Name` tag.

In a GeoEngineer resource the `_terraform_id` is the id used by Terraform and the `_geo_id` is GeoEngineer ID. By default a resources `_geo_id` is the same as the `_terraform_id`, so for most resources only the `_terraform_id` is required.

If `_terraform_id` is generated then the remote resource needed to be fetched via API and matched to the codified resource with `_geo_id`. This is done by implementing the `self._fetch_remote_resources` method to use the API and return a list of resources as an array of hashes each containing keys `_terraform_id` and `_geo_id`, then GeoEngineer will automatically match them.

For example, in `aws_security_group`'s the resource is matched based on the `Name` tag, implements as:

```ruby
class GeoEngineer::Resources::AwsSecurityGroup < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider)
      .describe_security_groups['security_groups']
      .map(&:to_h).map do |sg|
        sg[:name] = sg[:group_name]
        sg[:_terraform_id] = sg[:group_id]
        sg[:_geo_id] = sg[:tags] ? sg[:tags].select { |x| x[:key] == "Name" }.first[:value] : nil
        sg
    end
  end
end
```

### Adding a New Provider

Adding resources for a new provider requires creating a new subfolder and resources referencing the provider name in `lib/geoengineer/resources/`. If necessary, utility methods for the new provider client are stored at `lib/geoengineer/utils/`. Once the resources files are defined, no further setup is needed as provider information is pulled in from resource definitions in the project files being planned and applied.

### Validations

Terraform does not validate a lot of attributes before they are sent to the cloud. This means that often plans will fail for reasons that could have been initially validated. When creating a resource think about what validations could be done to ensure a plan is successful.

For example, a security groups needs a `Name` tag, requires a `name` and `description`, and a more complicated example is that its `cidr_blocks` should be valid:

```ruby
class GeoEngineer::Resources::AwsSecurityGroup < GeoEngineer::Resource
  # ...
  validate :validate_correct_cidr_blocks
  validate -> { validate_required_attributes([:name, :description]) }
  validate -> { validate_has_tag(:Name) }

  def validate_correct_cidr_blocks
    errors = []
    (self.all_ingress + self.all_egress).each do |in_eg|
      next unless in_eg.cidr_blocks
      in_eg.cidr_blocks.each do |cidr|
        begin
          NetAddr::IPv4Net.parse(cidr)
        rescue NetAddr::ValidationError
          errors << "Bad cidr block \"#{cidr}\" #{for_resource}"
        end
      end
    end
    errors
  end
  # ...
end
```

### Terraform State

Terraform by default will attempt to sync its resources with the API so that its state file is up to date with the real world. Given that GeoEngineer uses Terraform in a different way this sometimes causes plans to list changes that have already happened.

To fix this issue a resource can override `to_terraform_state` method, e.g. `aws_db_instance` has issues with `final_snapshot_identifier` updating:


```ruby
class GeoEngineer::Resources::AwsDbInstance < GeoEngineer::Resource
  # ...
  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'final_snapshot_identifier' => final_snapshot_identifier,
    }
    tfstate
  end
  # ...
end
```

## GeoEngineer Reference

The core models in GeoEngineer are:

```
 +-------------+ 1
 | Environment +-----------+
 +-------------+           |
       | 1                 |
       |                   |
       v *                 v *
 +-----+-------+ 1  * +-------------+ 1  *  +-------------+
 | Project     +----->+ Resource    +------>+ SubResource |
 +-------------+      +-------------+       +-------------+
```


1. `Environment` contains many resources that may exist outside of a project, like VPCs or routing tables. Also every project defined to be in the environment, for example the `test_www` project is in `staging` but `monorail` is in `staging` and `production` environments.
2. `Project` contains many resources and services grouped together into a name.
3. `Resource` and `SubResource` are based off of how terraform models cloud resources. A `Resource` instance can have many `SubResource` instances, but a `SubResource` instance belongs to only one `Resource` instance, e.g. a load balancer resource may have a `health_check` sub-resource to only allow specific incoming ports.

All these models can have arbitrary attributes assigned to them either by directly assigning on the instance, or through passing a block to the constructor. For example:

```ruby
resource = Resource.new('type','id') { |res|
  # CORRECT
  res.hello = 'hey'
  puts res.hello # 'hey'
  hello 'hey again' #
  puts res.hello # 'hey again'

  # INCORRECT way of assigning variables
  goodbye = 'nooo' # This assigns a local variable, not an attribute on the resource
  puts res.goodbye # nil
}

puts resource.hello # 'hey again'

resource.goodbye = 'see ya'
puts resource.goodbye # 'see ya'
```

Additionally, if the value is expensive to calculate or requires other attributes not yet assigned, an attribute can be assigned a `Proc` or `lambda` which will be calculated lazily:

```ruby
resource = Resource.new('type','id')
resource.lazy_attr = -> { puts "CALCULATING THE VALUE"; 'value' }
# ...
puts resource.lazy_attr
#$ "CALCULATING THE VALUE"
#$ "value"
```

### Environment

The top level class in GeoEngineer is the `environment`: it contains all projects, resources and services, and there should only ever be one initialized at a time.

An environment can mean many things to different people, e.g. an AWS account, an AWS region, or a specific AWS VPC. The only real constraint is that a resource has one instance per environment, e.g. a load balancer that is defined to be in `staging` and `production` environments, will have an instance in each.

The function `environment` is provided as a factory to build an environment:

```ruby
environment = environment("environment_name") { |e|
  e.attr_1 = [1,2,3]
  attr_2 'value'
}
environment.attr_3 = "another value"
```

### Project

A project is a group of resources typically provisioned to deploy one code base. A project has an `organization` and `name`, to mimic the github `username`/`organiztion` and `repository` structure.

A project is defined like:

```ruby
project = project('org', 'project_name') {
  environments 'staging', 'production'
}
```

This projects organization is `org`, its name `project_name` and will be provisioned in the `staging` and `production` environments. The `org` and `name` must be unique across all other projects.

The method `project` will automatically add the project to the instantiated environment object **only if** that environment's name is in the list of environments, otherwise it is ignored.

### Resources and SubResources

Resources are defined to be similar to the [terraform resource](https://www.terraform.io/docs/configuration/resources.html) configuration. The main difference is to not use `=` as this will create a local ruby variable and not assign the value.

A `Resource` can be created with and `environment` or `project` object (this will add that resource to that object):

```ruby
environment.resource('type', 'identifier') {
  name "resource_name"
  subresource {
    attribute "attribute"
  }
}

project.resource('type', 'identifier') {
  # ...
}
```

The `type` of a resource must be a valid terraform type, where AWS types are listed [here](https://www.terraform.io/docs/providers/aws/index.html). Some resources are not supported yet by GeoEngineer.

`identifier` is used by GeoEngineer and terraform to reference this resource must be unique, however it is not stored in the cloud so can be changed without affecting a plan.

A resource also has a ruby block sent to it that contains parameters and sub-resources. These values are defined by terraform so for reference to what values are required please refer to the [terraform docs](https://www.terraform.io/docs/providers/aws/index.html).
