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
      metr = YAML.load_stream(yaml_metrics).documents
      commit_info = {
        :id => commit.id,
        :author => commit.author.name.inspect,
        :author_email => commit.author.email,
        :changed_files => `git show --pretty=format: --name-only #{commit.id}`.split.join(',').inspect,
        :date => commit.authored_date.rfc2822.inspect
      }
      if pa = commit.previous_wanted
        commit_info[:previous_wanted] = commit.previous_wanted.id
      else
        commit_info[:previous_wanted] = ""
      end
      metr << commit_info
      metr
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
        proj_name = Dir.chdir(git_dir = options[:folder]) do
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
    proj_log = nil
    Dir.chdir previous_dir do
      proj_log = Log.new(proj_name)
    end
    mh = []
    Dir.chdir(git_dir) do
      wl = tree.wanted_list
      Message::Commit.count wl.size
      error_counter = 0
      wl.each do |commit|
        if metr = metrics(commit) then
          mh << metr
          Message::Commit.passed
        else
          Message::Commit.failed
          proj_log.error(commit.id)
        end
      end
      Message.error_count proj_log.errors
    end
    if options[:keep_temporary_folder]
      Message.warning "The temporary folder (/tmp/#{proj_name}) was kept."
    else
      FileUtils.rm_r proj_name, :force => true
    end
    [mh, proj_name]
  end
  def self.metrics_to_csv_line(metr) # This shoudn't really be here, but I'm still deciding where to put it.
    commit = metr[-1]
    if metr then
      csv_string = ""
      csv_string << commit[:id]; csv_string << ","
      csv_string << commit[:previous_wanted]; csv_string << ","
      csv_string << commit[:author]; csv_string << ","
      csv_string << commit[:author_email]; csv_string << ","
      
      csv_string << metr[0].keys.sort.map{|key| metr[0][key]}.join(','); csv_string << ","
      csv_string << commit[:changed_files]; csv_string << ","
      csv_string << commit[:date]
    end
  end
end

