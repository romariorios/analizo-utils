class Message
  class Commit
    def self.count(c)
      if c == 0 then
        puts "No relevant commits to process."
      else
        print "Processing " 
        if c == 1 then
          puts "one commit"
        else
          puts "#{c} commits"
        end
      end
    end
    def self.failed
      print "E"
    end
    def self.passed
      print "."
    end
  end
  def self.done
    puts "Done."
  end
  def self.downloading
    puts "Downloading the project..."
  end
  def self.error_count(c)
    if c == 0 then
      puts "\nDone.\n"
    else
      if c == 1 then
        print "\nOne error"
      else
        print "\n#{c} errors"
      end
      puts " ocurred. Check analizo.log and doxyparse.log for more details.\n"
    end
  end
  def self.info(msg)
    puts msg
  end
  def self.fatal(msg)
    puts "fatal: #{msg}"
    exit
  end
  def self.not_implemented(feature = "feature")
    print "Sorry, #{feature} not implemented yet."
  end
  def self.usage
    puts "Usage:\n   #{$PROGRAM_NAME} repository-url\n   #{$PROGRAM_NAME} -f repository-folder\n   Command-line options:\n     -s or --svn : The url passed is a Subversion repository.\n     -k or --keeptmp : Keep the temporary folder used to take the metrics (recommended for --svn)."
    exit
  end
  def self.warning(msg)
    puts "Warning: #{msg}"
  end
end
