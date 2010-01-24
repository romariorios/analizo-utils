require 'Grit::Commit-extension'
require 'Message'
require 'VersionControl'
require 'defs'
require 'yaml'
require 'benchmark'
require 'fileutils'

class AnalizoRunner
  def self.metrics(commit)
    system "git checkout #{commit} > /dev/null 2>> git.log"
    if "" == yaml_metrics = `analizo-metrics . 2> /dev/null` then
      false
    else
      YAML.load_stream(yaml_metrics).documents
    end
  end
  def self.metrics_history(options) # That's actually the main program
    previous_dir = Dir.pwd
    Dir.chdir("/tmp")
    begin
      if options.has_key?(:url)
        Message.downloading
        if "" != git_dir = VersionControl.clone(options[:url], options[:version_control]).split("\n")[0]
          tree = Grit::Repo.new(git_dir = git_dir.split[5]+"..").commits.first
        else
          exit
        end
        proj_name = git_dir.split("/")[-3]
        Message.done
      elsif options.has_key?(:folder)
        proj_name = Dir.chdir(git_dir = previous_dir+"/"+options[:folder]) do
          Dir.pwd.split("/")[-1]
        end
        FileUtils.cp_r git_dir, "/tmp/#{proj_name}"
        tree = Grit::Repo.new(git_dir = "/tmp/#{proj_name}").commits.first
      end
    rescue Grit::InvalidGitRepositoryError
      Message.fatal("Not a git repository.")
    rescue Grit::NoSuchPathError
      Message.fatal("The temporary folder couldn't be created.")
    end
    Dir.chdir(git_dir) do
      system "echo \"Log opened at: #{Time.now}\" >> git.log"
      system "echo \"Log opened at: #{Time.now}\" >> analizo.log"
      system "echo \"Log opened at: #{Time.now}\" >> doxyparse.log"
      system "git checkout master > /dev/null 2>> git.log"
      
      File.open(previous_dir+"/#{time_start_str = Time.now.strftime('%Y%m%d%H%M%S')}-#{proj_name}-metrics.csv", 'w') do |file|
        file.puts "commit_id,nearest_changed_ancestral_id,author,e-mail,average_cbo,average_lcom4,cof,sum_classes,sum_nom,sum_npm,sum_npv,sum_tloc,changed_files,date\n"
        wl = tree.wanted_list
        Message::Commit.count(wl.size)
        error_counter = 0
        wl.each do |commit|
          if mcsv = AnalizoRunner.metricsCSV(commit) then
            file.puts mcsv
            Message::Commit.passed
          else
            Message::Commit.failed
            system "echo \"Error processing commit #{commit}.\" >> analizo.log 2>> analizo.log"
            system "echo \"Analizo out:\" >> analizo.log 2>> analizo.log"
            system "analizo-metrics . >> analizo.log 2>> analizo.log"
            system "echo \"Error processing commit #{commit}.\" >> doxyparse.log 2>> doxyparse.log"
            system "echo \"Doxyparse out:\" >> doxyparse.log 2>> doxyparse.log"
            system "doxyparse . >> doxyparse.log 2>> doxyparse.log"
            error_counter +=1
          end
        end
        Message.error_count error_counter
        system "git checkout master > /dev/null 2>> git.log"
      end
      system "echo \"Log closed at: #{Time.now}\" >> git.log"
      system "echo \"Log closed at: #{Time.now}\" >> analizo.log"
      system "echo \"Log closed at: #{Time.now}\" >> doxyparse.log"
      Dir.mkdir(logs_dir = previous_dir+"/#{time_start_str}-#{proj_name}-logs")
      FileUtils.cp "git.log", logs_dir
      FileUtils.cp "analizo.log", logs_dir
      FileUtils.cp "doxyparse.log", logs_dir
    end
    if options[:keep_temporary_folder]
      Message.warning "The temporary folder (/tmp/#{proj_name}) was kept."
    else
      FileUtils.rm_r proj_name, :force => true
    end
  end
  def self.metricsCSV(commit) # This shoudn't really be here, but I'm still deciding where to put it.
    metr = metrics(commit)
    if metr then
      csv_string = ""
      csv_string << commit.id; csv_string << ","
      if pa = commit.previous_wanted then
        csv_string << commit.previous_wanted.id
      end
      csv_string << ","
      csv_string << commit.author.name.inspect; csv_string << ","
      csv_string << commit.author.email; csv_string << ","
      
      csv_string << metr[0].keys.sort.map{|key| metr[0][key]}.join(','); csv_string << ","
      csv_string << `git show --pretty=format: --name-only #{commit.id}`.split.join(',').inspect; csv_string << ","
      csv_string << commit.authored_date.rfc2822.inspect
    end
  end
end

