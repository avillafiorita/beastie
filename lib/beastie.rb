require 'pathname'
require 'optparse'

require_relative "beastie/version"
require_relative "beastie/issue"

module Beastie

  # tell option parser to accept an existing directory
  OptionParser.accept(Pathname) do |pn|
    Pathname.new(pn) if pn
    raise OptionParser::InvalidArgument, pn if not Dir.exist?(pn)
  end

  # Bestie manages issues from the command line.
  # Each issue is a text file in YAML, whose name is Jekyll-post like: DATE-TITLE.yml
  #
  # Two simple commands
  # - beastie new (create a new issue in the current directory
  # - beastie list (list relevant firelds of issues stored in the current directory)

  class Runner
    # the editor to use with the edit command
    EDITOR = "emacsclient"
    
    def self.run(args)

      # options = {}

      # global_options = OptionParser.new do |opts|
      #   opts.banner = "Usage: beastie [global options] <command> [[command options] <args>]"
        
      #   # Mandatory argument.
      #   opts.on("-d", "--directory DIR", Pathname,
      #           "Use DIR as the directory to store (and retrieve) issues") do |dir|
      #     options[:dir] = dir
      #   end
      # end

      # global_options.order!
      command = args[0]
      args.shift

      case command

      when "new"
        if args.size != 0
          puts "beastie error: too many arguments.\n"
          help
          exit 1
        end

        issue = Issue.new
        issue.ask
        issue.save

      when "edit"
        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > Issue.count
          puts "beastie error: please specify an issue.\n\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        shell_editor = `echo ${EDITOR}`.chomp
        editor = shell_editor == "" ? EDITOR : shell_editor
        system("#{editor} #{Issue.filename issue_no}")

      when "nedit"
        title = args.join(" ") # get all arguments (so that no " are necessary)
        if title == ""
          puts "beastie error: please specify the title of the issue.\n"
          help
          exit 1
        end

        issue = Issue.new
        issue.set_fields title
        issue.save

        shell_editor = `echo ${EDITOR}`.chomp
        editor = shell_editor == "" ? EDITOR : shell_editor
        system("#{editor} #{issue.filename}")

      when "show"
        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > Issue.count
          puts "beastie error: please specify an issue.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        system("cat #{Issue.filename issue_no}")

      when "change"
        if args.size != 3 or not digits_only(args[0]) or args[0].to_i > Issue.count
          puts "beastie error: could not parse command line.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        field = args[1]
        value = args[2]
        issue = Issue.new
        issue.load(Issue.filename issue_no)
        issue.change field, value
        issue.save

      when "close"
        if args.size != 1 or not digits_only(args[0]) or args[0].to_i > Issue.count
          puts "beastie error: please specify an issue.\n"
          help
          exit 1
        end

        issue_no = args[0].to_i
        issue = Issue.new
        issue.load(Issue.filename issue_no)
        issue.change "status", "closed"
        issue.save
        
      when "list"
        Beastie::Issue.list

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
      puts "beastie <command> [<args>]"
      puts ""
      puts "A simple command-line bug-tracking system"
      puts ""
      puts "Commands:"
      puts "  new             create a new issue in current directory"
      puts "  nedit    title  create an issue template and edit it with default editor"
      puts "  list            list all issues stored in current directory"
      puts "  edit     N      edit issue with id N (where N is the output of the list command)"
      puts "  show     N      show issue with id N (where N is the output of the list command)"
      puts "  change   N f v  change value of field 'f' to 'v' in id N"
      puts "  close    N      shortcut for 'change N status closed'"
      puts "  version         print version number"
    end

    # check if str is composed by digits only
    def self.digits_only str
      str.each_char.map { |x| x >= '0' and x <= '9'}.all?
    end
  end

end
