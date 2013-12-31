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
    #           field name => input function, default value, prompt
    # 
    #   where 
    #
    #   * "input function" is a function to ask a value to the user. Use an empty
    #                      string for a value which is filled automatically
    #
    #   * "default value"  is the default value to assign to the field
    #
    #   * "prompt"         is what is asked to the user.  Use an empty string for
    #                      a value which is filled automatically.
    #
    # input function and default value are evaluated, so that computation can be performed
    #
    # - title, created, and status are compulsory: do not delete them
    #   (gen_filename depends upon title and created; the close
    #   command depends upon status)
    #
    INPUT_F=0
    DEFAULT=1
    PROMPT=2

    ISSUE_FIELDS = {
      "title"       => ["gets.chomp",  "'title'",    "Short description of the issue"], 
      "status"      => ["",            "'open'",     ""],
      "created"     => ["",            "Date.today", ""],
      "component"   => ["gets.chomp",  "''",         "Component affected by the issue"],
      "priority"    => ["get_int",     "3",          "Priority (an integer number, e.g., from 1 to 5)"],
      "severity"    => ["get_int",     "3",          "Severity (an integer number, e.g., from 1 to 5)"],
      "points"      => ["get_int",     "5",          "Points (an integer estimating difficulty of fix)"],
      "type"        => ["gets.chomp",  "'bug'",      "Type (e.g., story, task, bug, refactoring)"],
      "description" => ["get_lines",   "''",         "Longer description (terminate with '.')"]
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

    def initialize
      @issue = Hash.new
    end

    # interactively ask from command line all fields specified in ISSUE_FIELDS
    def ask
      ISSUE_FIELDS.keys.each do |key|
        puts "#{ISSUE_FIELDS[key][PROMPT]}: " if ISSUE_FIELDS[key][PROMPT] != ""
        @issue[key] = (eval ISSUE_FIELDS[key][INPUT_F]) || (eval ISSUE_FIELDS[key][DEFAULT])
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

    # initialize all fields with the default values
    # (and set title to the argument)
    def set_fields title
      ISSUE_FIELDS.keys.each do |k|
        @issue[k] = eval(ISSUE_FIELDS[k][DEFAULT])
      end
      @issue['title'] = title
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
