require 'rubygems'
require 'facets/integer/of'
require 'ftools'
load 'ParanoidPackrat.rb'

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
  # Created a bound on the size of the tempdir
  def build_temp_dir dir = nil, count = nil
    count ||= [300] # max number of files and dirs to be created - stored in an array to allow passing by reference
    unless dir # default case
      dir = PPCommon.mktempdir 'PP-test' 
    else
      Dir.mkdir(dir) unless File.exists?(dir) && File.directory?(dir)
    end
    loop do
      break if count[0].zero?
      case rand(8)
        when (0..4) ; count[0] -= 1 ; create_random_file dir
        when (5..6) ; count[0] -= 1 ; build_temp_dir "#{dir}/#{rand_file_name}", count
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

  #Instantiate a fake backup to work with in specing and testing
  #returns the name of the newly created temp fake backup
  def create_fake_backup
        dir=mktempdir
        File.makedirs dir + '/stuffs/dir'
        File.makedirs dir + '/dest'
        dir
  end

  #create files in the temp fake backup provided by bdir
  def make_fake_backup_file bdir
       `echo 'DEADBEEF' >> #{bdir}/never_changes.txt`
       '/stuffs/never_changes.txt'
  end

  #wrapper to config
  def configure_backup name, bdir
        PPConfig.addName name
        PPConfig.setBackupTarget name, bdir + '/stuffs'
        PPConfig.setBackupDestinationOn name, bdir + '/dest'
        :christ_waffers!
  end

  #create a fake backup to assist with testing and specing shrinkBackupDestination
  #creates a set of files, backs them up once, makes some changes, backs them up again,
  #makes one last set of changes, backs those up, and is done.  So it creates files, and
  #and then makes changes and backs them up twice.
  #It returns the directory containing the fake backup target and destination.
  def create_fake_backup_target
    PPConfig.silentMode
    dir=mktempdir
    backupTarget=dir + '/stuffs'
    File.makedirs backupTarget + '/dir'
    File.makedirs dir + '/dest'
    `echo "I'm data that always changes! #{rand.to_s}" >> #{backupTarget}/always_changing.txt`
    `echo "I'm data that never changes. #{same=rand.to_s}" >> #{backupTarget}/never_changes.txt`
    `touch #{backupTarget}/emptyfile.txt`
    `echo "I'm data that always changes! #{rand.to_s}" >> #{backupTarget + '/dir/'}/always_changes.txt`
    `echo "I'm data that never changes. #{same} " >> #{backupTarget + '/dir/'}/never_changing.txt`
    `touch #{backupTarget}/dir/emptyfilez.txt`
    File.copy File.expand_path('spec/vanishing_file.rand'), backupTarget + '/.'
    File.copy File.expand_path('spec/hardlinked_file.rand'), backupTarget + '/hardlinked_file1.rand'
    File.copy File.expand_path('spec/hardlinked_file.rand'), backupTarget + '/omg_hardlinkedfile1.rand'
    File.link File.expand_path( backupTarget + '/hardlinked_file1.rand'), backupTarget + '/hardlinked_file2.rand'
    PPConfig.addName 'test_backup'
    PPConfig.setBackupTarget 'test_backup', backupTarget
    PPConfig.setBackupDestinationOn 'test_backup', dir + '/dest'
    PPIrb.simpleBackup PPConfig['test_backup']

    `echo " #{rand.to_s}" >> #{backupTarget}/always_changing.txt`
    `echo " #{rand.to_s}" >> #{backupTarget + '/dir/'}/always_changes.txt`
    File.delete backupTarget + '/vanishing_file.rand'
    PPIrb.simpleBackup PPConfig['test_backup']

    `echo " #{rand.to_s}" >> #{backupTarget}/always_changing.txt`
    `echo " #{rand.to_s}" >> #{backupTarget + '/dir/'}/always_changes.txt`
    File.copy File.expand_path('spec/vanishing_file.rand'), backupTarget + '/.'
    PPIrb.simpleBackup PPConfig['test_backup']

    PPConfig.silentMode
    backupTarget
  end
end
