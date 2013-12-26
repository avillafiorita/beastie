require 'date'
require 'tempfile'
require 'yaml'

module Beastie
  class Issue
    # A default issue has:
    #
    # - title
    # - status
    # - created
    # - component
    # - priority
    # - severity
    # - points
    # - type
    # - description
    #
    # Customizing the fields:
    #
    # - the fields aske by the new command are specified by the
    #   ISSUE_FIELDS variable
    #
    # - for each field, the structure if the following:
    #
    #           field name => init value, prompt
    # 
    #   where 
    #   * "init value" is evaluated (use "gets.chomp" to ask input)
    #   * prompt is what is asked to the user.  Use an empty string for
    #     a value which is filled automatically.
    # 
    # - title, created, and status are compulsory: do not delete them
    #   (gen_filename depends upon title and created; the close
    #   command depends upon status)
    #
    ISSUE_FIELDS = {
      "title"       => ["gets.chomp", "Short description of the issue"], 
      "status"      => ["'open'",     ""],
      "created"     => ["Date.today", ""],
      "component"   => ["gets.chomp", "Component affected by the issue"],
      "priority"    => ["get_int", "Priority (an integer number, e.g., from 1 to 5)"],
      "severity"    => ["get_int", "Severity (an integer number, e.g., from 1 to 5)"],
      "points"      => ["get_int", "Points (an integer estimating the difficulty of the issue)"],
      "type"        => ["gets.chomp", "Type (e.g., story, task, bug, refactoring)"],
      "description" => ["get_lines",  "Longer description (terminate with '.')"]
    }

    # which fields go to the report and formatting options
    REPORT_FIELDS = {
      "status"   => "%-10s",
      "type"     => "%-10s",
      "priority" => "%8s",
      "severity" => "%8s",
      "created"  => "%-10s",
      "title"    => "%-32s"
    }

    # these keep the actual values
    attr_reader :issue
    # the filename, after the issue has been saved or if it has been loaded
    attr_reader :filename

    # interactively ask from command line all fields specified in ISSUE_FIELDS
    def ask
      @issue = Hash.new

      ISSUE_FIELDS.keys.each do |key|
        puts "#{ISSUE_FIELDS[key][1]}: " if ISSUE_FIELDS[key][1] != ""
        @issue[key] = (eval ISSUE_FIELDS[key][0]) || ""
      end
    end
    
    # load from command line
    def load filename
      @filename = filename
      @issue = YAML.load_file(filename)
    end

    def change field, value
      @issue[field] = value
    end

    # save object to file
    def save
      @filename = @filename || gen_filename

      file = File.open(@filename, 'w') { |f|
        f.puts @issue.to_yaml
      }

      puts "Issue saved to #{filename}"
    end

    # return the n-th filename
    def self.filename n
      Dir.glob('*.{yml,yaml}')[n - 1]
    end

    # list all issues in current directory
    def self.list
      # print header
      printf "ID  "
      REPORT_FIELDS.keys.each do |key|
        printf REPORT_FIELDS[key] + " ", key
      end
      printf "\n"

      # print issues
      file_no = 0
      Dir.glob('*.{yml,yaml}') do |file|
        data = YAML.load_file(file)
        file_no += 1

        printf "%3d ", file_no
        REPORT_FIELDS.keys.each do |key|
          printf REPORT_FIELDS[key] + " ", data[key]
        end
        printf "\n"
      end
    end

    private 
   
    # read n-lines (terminated by a ".")
    def get_lines
      $/ = "\n.\n"  
      STDIN.gets.chomp("\n.\n")
    end
    
    # read an integer
    def get_int
      gets.chomp.to_i
    end

    # return a unique filename for this issue
    def gen_filename
      name = @issue["created"].strftime("%Y-%m-%d-") + 
             @issue["title"].gsub(/\W+/, "_") +
             ".yaml"
      n = 1
      while File.exist?(name)
        name = File.basename(name, ".yaml") + "-" + n.to_s + ".yaml"
        n += 1
      end

      name
    end

  end
end
