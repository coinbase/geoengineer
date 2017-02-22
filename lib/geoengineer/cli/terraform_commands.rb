########################################################################
# TerraformCommands provides command line terraform commands
# +plan+ and +apply+ for GeoEngineer
########################################################################
module GeoCLI::TerraformCommands # rubocop:disable Metrics/ModuleLength
  def create_terraform_files
    # create terraform file
    File.open("#{@tmpdir}/#{@terraform_file}", 'w') { |file|
      file.write(JSON.pretty_generate(@environment.to_terraform_json()))
    }

    # create terrafrom state
    File.open("#{@tmpdir}/#{@terraform_state_file}", 'w') { |file|
      file.write(JSON.pretty_generate(@environment.to_terraform_state()))
    }
  end

  def terraform_parallelism
    Parallel.processor_count * 3 # Determined through trial/error
  end

  def terraform_plan
    plan_command = [
      "cd #{@tmpdir}",
      "terraform plan -parallelism=#{terraform_parallelism}" \
      " -state=#{@terraform_state_file} -out=#{@plan_file} #{@no_color}"
    ].join(' && ')

    status, plan_output, plan_summary = run_and_collect_plan_output(plan_command)

    if status.exitstatus.zero?
      display_plan(plan_output.string)
      print plan_summary
    else
      puts "`#{plan_command}` exited with status #{status.exitstatus}"
    end

    status
  end

  def run_and_collect_plan_output(plan_command) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
    record = false
    plan_output = StringIO.new
    plan_summary = nil
    status = shell_exec_stream(plan_command) do |stdout_chunk, stderr_chunk|
      print stderr_chunk if stderr_chunk
      next unless stdout_chunk
      if record
        if stdout_chunk.include?('Plan:')
          plan_summary = stdout_chunk
          next
        end
        plan_output << stdout_chunk
      elsif stdout_chunk.include?("Path: #{@plan_file}")
        print stdout_chunk if @verbose
        # Once this output is received, the diff will follow, so start recording
        record = true
      elsif @verbose
        # Live stream output so user sees that work is happening
        print stdout_chunk
      end
    end

    [status, plan_output, plan_summary]
  end

  def display_plan(plan_output) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    scrubbed_output = plan_output.gsub(/\e\[\d+m/, '') # Remove ANSI escape sequences

    puts "----------------------------------------------\n" \
         "ORIGINAL TERRAFORM PLAN OUTPUT\n" \
         '----------------------------------------------'.colorize(:light_white)
    if String.disable_colorization
      print scrubbed_output
    else
      print plan_output
    end
    puts "----------------------------------------------\n" \
         "NEW PLAN OUTPUT\n" \
         '----------------------------------------------'.colorize(:light_white)

    begin
      plan = GeoEngineer::TerraformPlan.from_output(scrubbed_output)
      plan.display
    rescue GeoEngineer::TerraformPlan::ParseError => ex
      puts "ERROR: #{ex}".colorize(:red)
      puts ex.backtrace.join("\n").colorize(:red)
      puts "Original `terraform plan` output shown below:"
      # Gracefully degrade to showing the original output
      print scrubbed_output
    end
  end

  def terraform_apply
    apply_commands = [
      "cd #{@tmpdir}",
      "terraform apply -parallelism=#{terraform_parallelism}" \
      " -state=#{@terraform_state_file} #{@plan_file} #{@no_color}"
    ]
    shell_exec(apply_commands.join(" && "), true)
  end

  def plan_cmd
    command :plan do |c|
      c.syntax = 'geo plan [<geo_files>]'
      c.description = 'Generate and show an execution plan'
      action = lambda do |args, options|
        create_terraform_files
        terraform_plan
      end
      c.action init_action(:plan, &action)
    end
  end

  def apply_cmd
    command :apply do |c|
      c.syntax = 'geo apply [<geo_files>]'
      c.description = 'Apply an execution plan'
      action = lambda do |args, options|
        create_terraform_files
        return puts "Plan Broken" if terraform_plan.exitstatus.nonzero?
        return puts "Rejecting Plan" unless yes?("Apply the above plan? [YES/NO]")
        terraform_apply
      end
      c.action init_action(:apply, &action)
    end
  end
end
