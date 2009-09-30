require 'rubygems'
require 'facets/integer/of'

class Array
  def random
    entries[rand(length)]
  end
end

module TestLibrary
  #mktempdir(prefix = 'PP') will return a temp directory.
  #This directory is not yet, but should be auto-deleted on exit
  def mktempdir str = 'PP'
    str += '.XXXXXX' unless str =~ /X+$/
    `mktemp -td #{str}`.strip # Is there a better way?
  end
	
  def rand_file_name
    chars = ('a'..'z').collect + ('A'..'Z').collect + ('0'..'9').collect
    name = (rand(6) + 2).of { chars.random }.join
  end

  def create_random_file dir
    `touch '#{dir}/#{rand_file_name}'`
  end

  # Creates a tempdir, recursively populates it, returns a count of files and dirs"
  # No upper bound on size of tempdir created... can be slow
  def build_temp_dir dir = nil
    unless dir # default case
      dir = PPCommon.mktempdir 'PP-test' 
      (rand(5) + 3).times { create_random_file dir } # make more random files in top-level dir
    else
      Dir.mkdir(dir) unless File.exists?(dir) && File.directory?(dir)
    end
    loop do
      case rand(7)
        when (0..4) ; create_random_file dir
        when     5  ; build_temp_dir "#{dir}/#{rand_file_name}"
        else        ; break
      end
    end
    dir
  end

  # Counts the number of files and directories under a given dir
  def entries_under dir
    files = Dir.glob("#{dir}/**/*")
    files << dir
  end

   def wrap_io input = ''
    capture_stdout { wrap_input(input) { yield } }
  end
  def wrap_input input = ''
    stdin  = $stdin
    input  = StringIO.new input.to_s unless input.is_a? StringIO
    begin
      $stdin  = input
      yield
    ensure
      $stdin  = stdin
    end
  end
  def capture_stdout verbose = false
    stdout = $stdout
    out = StringIO.new "w+"
    begin
      $stdout = out
      yield
    ensure
      $stdout = stdout
      out.rewind
      data = out.read
      print data if verbose
      return data
    end
  end

end
