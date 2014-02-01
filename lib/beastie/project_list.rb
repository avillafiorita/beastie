require 'yaml'

module Beastie
  class Project
    CONFIG_FILE="#{Dir.home}/.beastie_config"

    def self.project_dir project
      Project.read
      @projects[project]["dir"]
    end

    private
    
    def self.read
      @projects = YAML.load_file(CONFIG_FILE)
    end

  end
end
