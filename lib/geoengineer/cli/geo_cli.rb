require_relative '../../geoengineer'
require 'open3'
require 'commander'
require 'colorize'
require 'terminal-table'
require 'fileutils'
require 'json'
require 'singleton'

# Create GeoCLI for the command requires
class GeoCLI
end

require_relative './status_command'
require_relative './terraform_commands'

def environment(name, &block)
  GeoCLI.instance.create_environment(name, &block)
end

def env
  GeoCLI.instance.environment
end

def project(org, name, &block)
  GeoCLI.instance.environment.project(org, name, &block)
end

# GeoCLI context
class GeoCLI
  include Commander::Methods
  include Singleton
  include StatusCommand
  include TerraformCommands

  attr_accessor :environment, :env_name

  # CLI FLAGS AND OPTIONS
  attr_accessor :verbose, :no_color

  def init_tmp_dir(name)
    @tmpdir = "#{Dir.pwd}/tmp/#{name}"
    FileUtils.mkdir_p @tmpdir
  end

  def init_terraform_files
    @terraform_file       = "terraform.tf.json"
    @terraform_state_file = "terraform.tfstate"
    @plan_file            = "plan.terraform"

    files = [
      "#{@tmpdir}/#{@terraform_state_file}.backup",
      "#{@tmpdir}/#{@terraform_file}",
      "#{@tmpdir}/#{@terraform_state_file}",
      "#{@tmpdir}/#{@plan_file}"
    ]

    files.each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  def create_environment(name, &block)
    return @environment if @environment
    if name != @env_name
      puts "Not loading environment #{name} as env_name is #{@env_name}" if @verbose
      return NullObject.new
    end

    @environment = GeoEngineer::Environment.new(name, &block)
    init_tmp_dir(name)
    init_terraform_files()
    @environment
  end

  def require_from_pwd(file)
    require "#{Dir.pwd}/#{file}"
  end

  def require_environment(options)
    @env_name = options.environment || ENV['GEO_ENV'] || 'staging'
    puts "Using environment '#{@env_name}'\n" if @verbose
    begin
      require_from_pwd "environments/#{@env_name}"
    rescue LoadError
      puts "unable to load 'environments/#{@env_name}'" if @verbose
    end
  end

  def require_all_projects
    Dir["#{Dir.pwd}/projects/**/*.rb"].each do |project_file|
      puts "LOADING #{project_file}" if @verbose
      require project_file
    end
  end

  def require_project_file(project_file)
    if !File.exist?(project_file) && !File.exist?("#{project_file}.rb")
      throw "The file \"#{project_file}\" does not exist"
    end
    require_from_pwd project_file
  end

  def require_geo_files(args)
    return require_all_projects if args.empty?
    args.each { |project_file| require_project_file(project_file) }
  end

  def print_validation_errors(errs)
    puts errs.map { |s| "ERROR: #{s}".colorize(:red) }
    puts "Total Errors #{errs.length}"
  end

  def shell_exec(cmd, verbose = @verbose)
    stdin, stdout_and_stderr, wait_thr = Open3.popen2e({}, *cmd)

    puts(">> #{cmd}\n") if verbose
    stdout_and_stderr.each do |line|
      puts(line) if verbose
    end
    puts("<< Exited with status: #{wait_thr.value.exitstatus}\n\n") if verbose

    stdin.close
    stdout_and_stderr.close

    wait_thr.value
  end

  # This defines the typical action in geo engineer
  # - require the environment
  # - require the geo files
  # - ensure everything is valid
  # - execute the action
  # - execute the after hook
  def init_action(action_name)
    lambda do |args, options|
      require_environment(options)
      require_geo_files(args)
      throw "Environment not set" unless @environment

      @environment.execute_lifecycle(:before, action_name.to_sym)
      errs = @environment.errors.flatten.sort
      unless errs.empty?
        print_validation_errors(errs)
        exit 1
      end

      yield args, options
      @environment.execute_lifecycle(:after, action_name.to_sym)
    end
  end

  def yes?(question)
    answer = ask question
    answer.strip.upcase.start_with? "YES"
  end

  def graph_cmd
    command :graph do |c|
      c.syntax = 'geo graph [<geo_files>]'
      c.description = 'Generate and graph of the environment resources to GraphViz'
      action = lambda do |args, options|
        puts env.to_dot
      end
      c.action init_action(:graph, &action)
    end
  end

  def global_options
    global_option('-e', '--environment <name>', "Environment to use")

    @verbose = true
    global_option('--quiet', 'reduce the noisy outputs (default they are on)') {
      @verbose = false
    }

    @no_color = ''
    global_option('--no-color', 'removes color from the terraform output') {
      String.disable_colorization = true
      @no_color = ' -no-color'
    }
  end

  def terraform_installed?
    terraform_version = shell_exec('which terraform')
    terraform_version.exitstatus.zero?
  end

  def run
    program :name, 'GeoEngineer'
    program :version, GeoEngineer::VERSION
    program :description, 'GeoEngineer will help you Terraform your resources'
    always_trace!

    # check terraform installed
    return puts "Please install terraform" unless terraform_installed?

    # global_options
    global_options

    # Add commands
    plan_cmd
    apply_cmd
    graph_cmd
    status_cmd

    # Execute the CLI
    run!
  end
end
