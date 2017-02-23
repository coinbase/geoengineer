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

  def run_and_collect_plan_output(plan_command) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
    record = false
    plan_output = StringIO.new
    plan_summary = nil
    status = shell_exec_stream(plan_command) do |stdout_chunk, stderr_chunk|
      print stderr_chunk if stderr_chunk
      next unless stdout_chunk
      if record
        if (m = stdout_chunk.match(/Plan[^\n]+/))
          match_start = m.begin(0)
          plan_output << stdout_chunk[0...match_start]
          plan_summary = stdout_chunk[match_start..-1]
          next
        else
          plan_output << stdout_chunk
        end
      elsif (m = stdout_chunk.match(/Path: #{@plan_file}[^\n]*/))
        match_start = m.begin(0)
        print stdout_chunk[0...match_start] if @verbose

        # Once this output is received, the diff will follow, so start recording
        record = true

        # Record anything that came after the "Path: ..." line
        plan_output << stdout_chunk[m.end(0)..-1]
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
         '----------------------------------------------'
    if String.disable_colorization
      print scrubbed_output
    else
      print plan_output
    end
    puts "----------------------------------------------\n" \
         "NEW PLAN OUTPUT\n" \
         '----------------------------------------------'

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
