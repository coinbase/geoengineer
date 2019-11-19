########################################################################
# TerraformCommands provides command line terraform commands
# +plan+ and +apply+ for GeoEngineer
########################################################################
module GeoCLI::TerraformCommands
  def create_terraform_files(with_state = true)
    # If GPS is included then write some files to help debug
    write_gps if @gps

    # create terraform file
    File.open("#{@tmpdir}/#{@terraform_file}", 'w') { |file|
      file.write(JSON.pretty_generate(@environment.to_terraform_json()))
    }

    # create terrafrom state if remote state is not supported
    write_state if with_state && !@environment.remote_state_supported?
  end

  def write_state
    File.open("#{@tmpdir}/#{@terraform_state_file}", 'w') { |file|
      file.write(JSON.pretty_generate(@environment.to_terraform_state()))
    }
  end

  def write_gps
    File.open("#{@tmpdir}/gps.yml", 'w') { |file|
      file.write(gps.to_h.to_yaml)
    }

    File.open("#{@tmpdir}/gps.expand.yml", 'w') { |file|
      file.write(gps.expanded_hash.to_yaml)
    }

    File.open("#{@tmpdir}/gps.constants.yml", 'w') { |file|
      file.write(gps.constants.to_h.to_yaml)
    }
  end

  def terraform_parallelism
    Parallel.processor_count * 3 # Determined through trial/error
  end

  def terraform_plan
    terraform_plan_commands = []
    terraform_plan_commands << "terraform plan --refresh=false -parallelism=#{terraform_parallelism}"
    terraform_plan_commands << "-state=#{@terraform_state_file}" unless env.remote_state_supported?
    terraform_plan_commands << "-out=#{@plan_file} #{@no_color}"
    plan_commands = [
      "cd #{@tmpdir}",
      "terraform init #{@no_color}",
      "terraform refresh #{@no_color}",
      terraform_plan_commands.join(" ")
    ]

    exit_code = shell_exec(plan_commands.join(" && "), true).exitstatus
    return unless exit_code.nonzero?
    puts "Plan Broken"
    exit exit_code
  end

  def terraform_plan_destroy
    terraform_plan_commands = []
    terraform_plan_commands << "terraform plan -destroy --refresh=false -parallelism=#{terraform_parallelism}"
    terraform_plan_commands << "-state=#{@terraform_state_file}" unless env.remote_state_supported?
    terraform_plan_commands << "-out=#{@plan_file} #{@no_color}"

    plan_destroy_commands = [
      "cd #{@tmpdir}",
      "terraform refresh #{@no_color}",
      terraform_plan_commands.join(" ")
    ]

    shell_exec(plan_destroy_commands.join(" && "), true)
  end

  def terraform_apply
    apply_commands = [
      "cd #{@tmpdir}",
      "terraform apply -parallelism=#{terraform_parallelism}" \
      " #{@plan_file} #{@no_color}"
    ]
    shell_exec(apply_commands.join(" && "), true)
  end

  def terraform_destroy
    destroy_commands = [
      "cd #{@tmpdir}",
      "terraform apply -parallelism=#{terraform_parallelism}" \
      " #{@plan_file} #{@no_color}"
    ]
    shell_exec(destroy_commands.join(" && "), true)
  end

  def test_cmd
    command :test do |c|
      c.syntax = 'geo test [<geo_files>]'
      c.description = 'Generates files while mocking AWS (useful for testing/debugging)'
      action = lambda do |args, options|
        create_terraform_files(false)
      end
      c.action ->(args, options) { GeoCLI::TestCmdStubs.stub! && init_action(:plan, &action).call(args, options) }
    end
  end

  def plan_cmd
    command :plan do |c|
      c.syntax = 'geo plan [<geo_files>]'
      c.description = 'Generate and show an execution plan'
      c.option '--allow-destroy', 'Run the plan with allow_destroy = true, useful for debugging'
      action = lambda do |args, options|
        # check terraform installed
        return puts "Please install terraform" unless terraform_installed?

        env.allow_destroy(true) if options.allow_destroy
        create_terraform_files
        terraform_plan
      end
      c.action init_action(:plan, &action)
    end
  end

  def apply_cmd
    command :apply do |c|
      c.syntax = 'geo apply [<geo_files>]'
      c.option '--yes', 'Ignores the sanity check'
      c.description = 'Apply an execution plan'
      action = lambda do |args, options|
        # check terraform installed
        return puts "Please install terraform" unless terraform_installed?

        create_terraform_files
        terraform_plan
        unless options.yes || yes?("Apply the above plan? [YES/NO]")
          puts "Rejecting Plan"
          exit 1
        end
        exit_code = terraform_apply.exitstatus
        exit exit_code if exit_code.nonzero?
      end
      c.action init_action(:apply, &action)
    end
  end

  # rubocop:disable Metrics/AbcSize
  def destroy_cmd
    command :destroy do |c|
      c.syntax = 'geo destroy [<geo_files>]'
      c.description = 'Destroy an execution plan'
      action = lambda do |args, options|
        # check terraform installed
        return puts "Please install terraform" unless terraform_installed?

        create_terraform_files
        exit_code = terraform_plan_destroy.exitstatus
        if exit_code.nonzero?
          puts "Plan Broken"
          exit exit_code
        end
        unless yes?("Apply the above plan? [YES/NO]")
          puts "Rejecting Plan"
          exit 1
        end
        exit_code = terraform_destroy.exitstatus
        exit exit_code if exit_code.nonzero?
      end
      c.action init_action(:destroy, &action)
    end
  end
  # rubocop:enable Metrics/AbcSize
end
