require 'date'
require 'tempfile'
require 'yaml'
require 'readline'

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
    # input function and default value are evaluated, so that computation can
    # be performed
    #
    # - title, created, and status are compulsory: do not delete them
    #   (gen_filename depends upon title and created; the close
    #   command depends upon status)
    #
    INPUT_F=0
    DEFAULT=1
    PROMPT=2

    ISSUE_FIELDS = {
      "title"       => ["Readline.readline",  "'title'",    "Short description of the issue"], 
      "status"      => ["",            "'open'",     ""],
      "created"     => ["",            "Date.today", ""],
      "component"   => ["Readline.readline",  "''",         "Component affected by the issue"],
      "priority"    => ["get_int",     "3",          "Priority (an integer number, e.g., from 1 to 5)"],
      "severity"    => ["get_int",     "3",          "Severity (an integer number, e.g., from 1 to 5)"],
      "points"      => ["get_int",     "5",          "Points (an integer estimating difficulty of fix)"],
      "type"        => ["Readline.readline",  "'bug'",      "Type (e.g., story, task, bug, refactoring)"],
      "description" => ["get_lines",   "''",         "Longer description (terminate with '.')"]
    }

    # which fields go to the report and formatting options
    REPORT_FIELDS = {
      "status"   => "%-10s",
      "type"     => "%-12s",
      "priority" => "%8s",
      "severity" => "%8s",
      "created"  => "%-10s",
      "title"    => "%-30s"
    }

    # the directory where all issues of this instance are stored
    attr_reader :dir

    # the filename of this issue.
    # IT IS ALWAYS A BASENAME. @dir is added only when needed (e.g. load)
    attr_reader :filename

    # the values (a Hash) of this issue
    attr_reader :issue

    def initialize directory
      @dir = directory
      @issue = Hash.new
    end

    # interactively ask from command line all fields specified in ISSUE_FIELDS
    def ask
      ISSUE_FIELDS.keys.each do |key|
        puts "#{ISSUE_FIELDS[key][PROMPT]}: " if ISSUE_FIELDS[key][PROMPT] != ""
        @issue[key] = (eval ISSUE_FIELDS[key][INPUT_F]) || (eval ISSUE_FIELDS[key][DEFAULT])
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

    def change field, value
      @issue[field] = value
    end

    # load from command line
    def load filename
      @filename = File.basename(filename)
      @issue = YAML.load_file(File.join(@dir, @filename))
    end

    # load by issue id
    # @dir must be set, which is always the case because of
    #      the constructor
    def load_n n
      load id_to_full_filename n
    end

    def id_to_full_filename n
      Dir.glob(File.join(@dir, '*.{yml,yaml}'))[n - 1]
    end

    # return the full filename, if @filename is set 
    # (load, save, ...)
    def full_filename
      File.join(@dir, @filename)
    end

    # save object to file
    def save
      @filename = @filename || gen_filename
      file = File.open(File.join(@dir, @filename), 'w') { |f|
        f.puts @issue.to_yaml
      }
    end

    # count all issues in current directory to get the maximum ID
    def count
      Dir.glob(File.join(@dir, '*.{yml,yaml}')).size
    end

    # list all issues in current directory
    def list condition
      # print header
      printf "ID  "
      REPORT_FIELDS.keys.each do |key|
        printf REPORT_FIELDS[key] + " ", key
      end
      printf "\n"

      # print issues
      file_no = 0
      Dir.glob(File.join(@dir, '*.{yml,yaml}')) do |file|
        data = YAML.load_file(file)
        file_no += 1

        # create a string with all the bindings
        assignments = ""
        REPORT_FIELDS.keys.each do |key|
          # not sure why, but using classes does not work..
          # so I make them into strings
          case data[key].class.to_s
          when "Fixnum"
            assignments << "#{key} = #{data[key]};"
          when "String"
            assignments << "#{key} = '#{data[key]}';"
          when "Date"
            assignments << "#{key} = Date.parse('#{data[key]}');"
          end
        end

        if eval (assignments + condition) then
          printf "%3d ", file_no
          REPORT_FIELDS.keys.each do |key|
            printf REPORT_FIELDS[key] + " ", data[key]
          end
          printf "\n"
        end
      end
    end

    private 
   
    # read n-lines (terminated by a ".")
    def get_lines
      lines = []
      line = ""
      until line == "."
        line = Readline.readline
        lines << line
      end
      lines.join("\n")
    end
    
    # read an integer
    def get_int
      Readline.readline.to_i
    end

    # generate a unique filename for this issue
    #
    # (notice that @dir is prepended, to make sure it is unique
    # in the right directory)
    def gen_filename
      name = @issue["created"].strftime("%Y-%m-%d-") + 
             @issue["title"].gsub(/\W+/, "_") +
             ".yaml"
      n = 1
      while File.exist?(File.join(@dir, name))
        name = File.basename(name, ".yaml") + "-" + n.to_s + ".yaml"
        n += 1
      end

      name
    end

  end
end
