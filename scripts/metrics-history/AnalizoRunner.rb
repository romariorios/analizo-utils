require 'Grit::Commit-extension'
require 'Log'
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
  
  # This is actually the main program. It should not be here, not this way,
  # but I will keep it for a while, until I either refactor it and really 
  # make it fit to this class (namespace?) or find a new class for it.
  def self.metrics_history(options)
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
    proj_log = Log.new(proj_name)
    Dir.chdir(git_dir) do      
      File.open(previous_dir+"/#{time_start_str = Time.now.strftime('%Y%m%d%H%M%S')}-#{proj_name}-metrics.csv", 'w') do |file|
        file.puts "commit_id,nearest_changed_ancestral_id,author,e-mail,average_cbo,average_lcom4,cof,sum_classes,sum_nom,sum_npm,sum_npv,sum_tloc,changed_files,date\n"
        wl = tree.wanted_list
        Message::Commit.count wl.size
        error_counter = 0
        wl.each do |commit|
          if mcsv = metricsCSV(commit) then
            file.puts mcsv
            Message::Commit.passed
          else
            Message::Commit.failed
            proj_log.error(commit.id)
          end
        end
        Message.error_count proj_log.errors
      end
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

