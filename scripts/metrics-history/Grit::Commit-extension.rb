require 'rubygems'
require 'grit'

class Grit::Commit
  def merge?
    self.parents.size > 1
  end
  def parentless
    self.parents.size == 0
  end
  def wanted?
    files = `git show --pretty=format: --name-only #{id}`.split
    matches = (files.any? { |path| path =~ FILTER })
    !merge? && matches 
  end
  def previous_wanted
    if merge? || parentless
      nil
    else
      previous = self.parents.first
      if previous.wanted?
        previous
      else
        previous.previous_wanted
      end
    end
  end
  def wanted_list
    commit = self.wanted? ? self : self.previous_wanted
    if commit
      result = []
      while commit
        result << commit
        commit = commit.previous_wanted
      end
      result
    else
      []
    end
  end
end
