require_relative '../../geoengineer'
require 'open3'
require 'commander'
require 'colorize'
require 'fileutils'
require 'json'
require 'singleton'

# Create GeoCLI for the command requires
class GeoCLI
end

require_relative './status_command'
require_relative './test_cmd_stubs'
require_relative './terraform_commands'
require_relative './gps_commands'

# GeoCLI context
class GeoCLI
  include Commander::Methods
  include Singleton
  include StatusCommand
  include TerraformCommands
  include GPSCommands
  include HasLifecycle

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
      "#{@tmpdir}/gps.yml",
      "#{@tmpdir}/gps.expand.yml",
      "#{@tmpdir}/gps.constants.yml",
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

  def gps
    return @gps if @gps
    require_gps
    constants = GeoEngineer::GPS.load_constants("#{Dir.pwd}/environments/")
    @gps ||= GeoEngineer::GPS.load_projects("#{Dir.pwd}/projects/", constants)
  end

  def require_gps
    dir = "#{Dir.pwd}/gps/"

    # No directory
    return nil unless Dir.exist?(dir)

    # Additional GPS information
    require "#{dir}/gps.rb" if File.exist? "#{dir}/gps.rb"
  end

  def require_environment(options = nil)
    @env_name = options&.environment || ENV['GEO_ENV'] || 'development'
    puts "Using environment '#{@env_name}'\n" if @verbose
    begin
      require_from_pwd "environments/#{@env_name}"
    rescue LoadError => e
      puts "unable to load 'environments/#{@env_name}': #{e}" if @verbose
    end
  end

  def require_all_projects
    Dir["#{Dir.pwd}/projects/**/*.rb"].each do |project_file|
      project_file = project_file.gsub("#{Dir.pwd}/", "")
      require_project_file(project_file)
    end

    Dir["#{Dir.pwd}/projects/**/*.gps.yml"].each do |gps_file|
      gps_file = gps_file.gsub("#{Dir.pwd}/", "")
      GeoEngineer::GPS.load_gps_file(gps, gps_file)
    end
  end

  # this method accepts .rb files and .gps.yml files
  def require_geo_files(files)
    # load everything if empty
    return require_all_projects if files.empty?

    # first require .rb files
    files.select { |file| file.end_with?(".rb") }
         .each { |project_file| require_project_file(project_file) }

    # next require .gps.yml files (if they were not required by)
    files.select { |file| file.end_with?(".gps.yml") }
         .each { |gps_file| GeoEngineer::GPS.load_gps_file(gps, gps_file) }
  end

  def require_project_file(project_file)
    unless File.exist?(project_file)
      throw "The file \"#{project_file}\" does not exist"
    end
    require_from_pwd(project_file)
  end

  def print_validation_errors(errs)
    errs = errs.sort.compact.uniq
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

    global_option('--no-mp', 'Removes the ability to monkey patch the CLI by including a .geo.rb file')
    global_option('--no-terraform', 'Removes the requirement for terraform to be installed')
  end

  def terraform_installed?
    terraform_version = shell_exec('which terraform')
    terraform_version.exitstatus.zero?
  end

  def pre_steps
    lambda do |args, options|
      # Require any patches to the way geo works
      require_from_pwd '.geo' if File.file?("#{Dir.pwd}/.geo.rb") && !options.no_mp

      # check terraform installed
      throw("Please install terraform") if !options.no_terraform && !terraform_installed?

      yield(args, options)
    end
  end

  def add_commands
    plan_cmd
    apply_cmd
    destroy_cmd
    graph_cmd
    status_cmd
    test_cmd
    query_cmd
    export_graph_command
    diff_graph_command
  end

  def run
    program :name, 'GeoEngineer'
    program :version, GeoEngineer::VERSION
    program :description, 'GeoEngineer will help you Terraform your resources'
    always_trace!

    # global_options
    global_options

    # Add commands
    add_commands
    execute_lifecycle(:after, :add_commands)

    # Execute the CLI
    run!
  end
end
