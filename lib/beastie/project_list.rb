require 'yaml'

module Beastie
  class ProjectList
    PROJECT_FILE="#{Dir.home}/.beastie_projects"

    def self.project_dir project_name
      projects = read 

      if projects and projects[project_name]
        projects[project_name]["dir"]
      else
        nil
      end
    end

    # an overkill ... system("cat #{PROJECT_FILE}") could work equally well
    def self.to_s
      output = ""
      projects = self.read
      projects.keys.each do |key|
        output << "#{key}:\n"
        output << "  dir: #{projects[key]["dir"]}\n"
      end
      output
    end

    private
    
    def self.read
      File.exists?(PROJECT_FILE) ? YAML.load_file(PROJECT_FILE) : nil
    end

  end
end
