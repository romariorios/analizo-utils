require 'defs'
require 'Message'

class Options < Hash
  def initialize(args = [])
    parse_by_command_line_args(args)
    if (self[:folder] != :none and self[:url] != :none) or (self[:folder] == :none and self[:url] == :none)
      Message.usage
    end
    if has_key?(:version_control)
      if !SUPPORTED_VERSION_CONTROL_SYSTEMS.include?(o_vc = self[:version_control])
        Message.not_implemented "#{o_vc} support"
      elsif has_key? :folder
        Message.not_implemented "#{o_vc} history from folders"
      end
    end
  end
  def parse_by_command_line_args(args)
    args.each_index do |i|
      if (ai = args[i])[0..0] != "-" and args[i-1] != "-f" and !self.has_key?(:folder) and !self.has_key?(:url)
        self[:url] = args[i]
      elsif ("-f" == ai or "--folder" == ai) and !self.has_key?(:folder)  and !self.has_key?(:url)
        self[:folder] = args[i+1]
      elsif "-k" == ai or "--keeptmp" == ai
        self[:keep_temporary_folder] = true
      else
        VERSION_CONTROL_SYSTEMS.each do |vcs|
          if (ai == vcs[0] or ai == vcs[1]) and !self.has_key?(:version_control)
            self[:version_control] = vcs[0][2..-1]
          end
        end
      end
      if self.has_key?(:folder)
        self[:url] = :none
      elsif self.has_key?(:url)
        self[:folder] = :none
      end
    end
  end
end

