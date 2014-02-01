require_relative "../lib/beastie/project_list"

require "test/unit"
require "tempfile"
 
# we need to override the PROJECT_FILE
class MyTestProjectList < Beastie::ProjectList
  # a hack to change the PROJECT_FILE constant to point to string
  def self.project_file string
    PROJECT_FILE.replace string
  end
end

class TestProjectList < Test::Unit::TestCase
  # if the project file does not exist, nil is returned
  def test_no_project_file
    MyTestProjectList.project_file Tempfile.new('foo').path
    assert_equal(nil, MyTestProjectList.project_dir('foo'))
  end
 
  # the file exists, it might or might not contain an entry
  def test_project_file
    MyTestProjectList.project_file Tempfile.new('foo').path
    File.open(MyTestProjectList::PROJECT_FILE, "w") do |f|
      f.puts <<-eos
foo:
  dir: /a/b/c
      eos
    end
    assert_equal("/a/b/c", MyTestProjectList.project_dir('foo'))
    assert_equal(nil, MyTestProjectList.project_dir('foolish'))
  end

  # the file exists, but it is wrongly configured (no dir entry)
  def test_wrong_project_file
    MyTestProjectList.project_file Tempfile.new('foo').path
    File.open(MyTestProjectList::PROJECT_FILE, "w") do |f|
      f.puts <<-eos
foo:
  directory: /a/b/c
      eos
    end
    assert_equal(nil, MyTestProjectList.project_dir('foo'))
  end


end
