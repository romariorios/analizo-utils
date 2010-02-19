class Log
  attr_reader :open, :errors
  def initialize(project = "project")
    @open = true
    @errors = 0
    @time_start_str = (@time_start = Time.now).strftime('%Y%m%d%H%M%S')
    Dir.mkdir(@logs_dir = "#{@time_start_str}-#{@project = project}-logs")
    Dir.chdir(@logs_dir) do
      system "echo \"Log opened at: #{@time_start}\" >> git.log"
      system "echo \"Log opened at: #{@time_start}\" >> analizo.log"
      system "echo \"Log opened at: #{@time_start}\" >> doxyparse.log"
      system "git checkout master > /dev/null 2>> git.log"
    end
  end
  def error(commit)
    if @open
      analizo_metrics = `analizo-metrics .  2>> boson && cat boson && rm boson`
      doxyparse = `doxyparse . 2>> boson && cat boson && rm boson`
      Dir.chdir(@logs_dir) do
        system "echo \"Error processing commit #{commit}.\" >> analizo.log"
        system "echo \"Analizo out:\" >> analizo.log"
        system "echo #{analizo_metrics} >> analizo.log"
        system "echo \"Error processing commit #{commit}.\" >> doxyparse.log"
        system "echo \"Doxyparse out:\" >> doxyparse.log"
        system "echo #{doxyparse} >> doxyparse.log"
      end
    end
    @errors += 1
  end
  def close!
    if @open
      git  = `git checkout master > /dev/null 2>> boson && cat boson && rm boson`
      Dir.chdir(@logs_dir) do
	system "echo #{git} >> git.log"
        system "echo \"Log closed at: #{@time_close = Time.now}\" >> git.log"
        system "echo \"Log closed at: #{@time_close = Time.now}\" >> analizo.log"
        system "echo \"Log closed at: #{@time_close = Time.now}\" >> doxyparse.log"
      end
      @open = false
    end
  end
end
