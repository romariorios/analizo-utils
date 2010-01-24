class VersionControl
  def self.clone(url, version_control = nil)
    if "svn" == version_control
      Message.warning "Converting from svn. This may take a long time."
      `git svn clone #{url}`
    else
      `git clone #{url}`
    end
  end
end

