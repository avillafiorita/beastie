require 'pathname'
require 'optparse'

require_relative "beastie/version"
require_relative "beastie/issue"
require_relative "beastie/project_list"

module Beastie

  # add an option to optparser to accept an existing pathname as option
  OptionParser.accept(Pathname) do |pn|
    Pathname.new(pn) if pn
    raise OptionParser::InvalidArgument, pn if not Dir.exist?(pn)
  end

  class Runner
    # the editor to use with the edit command
    EDITOR = "emacsclient"
    
    def self.run(args)

      # default directory is ".", unless -p is specified
      dir = "."
      OptionParser.new do |opts|
        opts.on("-p", "--project name", String,
                "Use project's dir for operations") do |name|
          dir = ProjectList.project_dir name
          
          if dir == nil then
            puts "beastie error: nothing known about project #{name}.\n"
            puts ""
            puts "add the following lines to #{ProjectList::PROJECT_FILE}"
            puts ""
            puts "#{name}:"
            puts "  dir: <directory where #{name} issues live>"
            exit 1
          end
        end

        opts.on("-d", "--directory name", String,
                "Use this directory for operations") do |name|
          dir = name
        end
      end.order!.parse!

      if not Dir.exists?(dir)
        puts "beastie error: the directory does not exist"
        puts ""
        puts "if you used -p, please check the #{ProjectList::PROJECT_FILE} file"
        exit 1
      end

      command = args[0]
      args.shift

      case command

      when "new"
        if args.size != 0
          puts "beastie error: too many arguments.\n"
          help
          exit 1
        end

        issue = Issue.new dir
        issue.ask
        issue.save
        puts "Issue saved to #{issue.full_filename}."

      when "nedit"
        title = args.join(" ") # get all arguments (so that no " are necessary)

        if title == ""
          puts "beastie error: please specify the title of the issue.\n"
          help
          exit 1
        end

        issue = Issue.new dir
        issue.set_fields title
        issue.save
        system("#{editor_cmd} #{issue.full_filename}")

      when "edit"
        issue = Issue.new dir

        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > issue.count
          puts "beastie error: please specify a valid identifier.\n\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        system("#{editor_cmd} #{issue.id_to_full_filename issue_no}")

      when "show"
        issue = Issue.new dir

        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > issue.count
          puts "beastie error: please specify an issue.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        system("cat #{issue.id_to_full_filename issue_no}")

      when "modify", "change"
        issue = Issue.new dir

        if args.size != 3 or not digits_only(args[0]) or args[0].to_i > issue.count
          puts "beastie error: could not parse command line.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        field = args[1]
        value = args[2]

        issue.load_n issue_no
        issue.change field, value
        issue.save
        puts "Issue #{issue_no} has now #{field} set to #{value}."

      when "close"
        issue = Issue.new dir

        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > issue.count
          puts "beastie error: please specify an issue.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        issue.load_n issue_no
        issue.change "status", "closed"
        issue.save
        puts "Issue #{issue_no} is now closed."
        
      when "list"
        issue = Issue.new dir
        issue.list

      when "help"
        help
        
      when "version"
        puts "beastie version #{VERSION}"

      else 
        help
      end

    end

    private

    def self.help
      puts <<-eos
beastie [-p <project> | -d <dir>] <command> [<args>]

A simple command-line bug-tracking system

Global options:
  -p <project>  (--project) command will operate on <project> (*)
  -d <dir>      (--directory) command will operate on directory <dir>

Commands:
  new             create a new issue in current directory
  nedit    title  create an issue template and edit it with default editor
  list            list all issues stored in current directory
  edit     N      edit issue with id N (where N is the output of the list command)
  show     N      show issue with id N (where N is the output of the list command)
  change   N f v  change value of field 'f' to 'v' in id N
  modify   N f v  change value of field 'f' to 'v' in id N
  close    N      shortcut for 'change N status closed'
  version         print version number

(*) To use this option, create a file #{ProjectList::PROJECT_FILE} containing
entries in the form:

<project1>:
  dir: <dir1>
<project2>:
  dir: <dir2>

For instance:

beastie:
  dir: /Users/guest/beastie

(in which case -p beastie is equivalent to -d /Users/guest/beastie)
eos
    end

    # check if str is composed by digits only
    def self.digits_only str
      str.each_char.map { |x| x >= '0' and x <= '9'}.all?
    end

    # get an editor
    def self.editor_cmd
      shell_editor = `echo ${EDITOR}`.chomp
      shell_editor == "" ? EDITOR : shell_editor
    end

  end

end
