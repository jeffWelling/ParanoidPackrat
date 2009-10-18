#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../spec"))

require 'PPCommon'
load 'TestLibrary.rb'
include TestLibrary

describe TestLibrary do
  it "creates an empty temp directory on request" do
    td = PPCommon.mktempdir
    File.exists?(   td).should == true
    File.directory?(td).should == true
  end
end

describe PPCommon do
  it "adds a slash to strings if they do not already end with one" do
    PPCommon.addSlash('foo' ).should == 'foo/'
    PPCommon.addSlash('foo/').should == 'foo/'
  end

  it "strips slashes from the end of a string" do
    PPCommon.stripSlash('foo'  ).should == 'foo'
    PPCommon.stripSlash('foo/' ).should == 'foo'
    PPCommon.stripSlash('foo//').should == 'foo'
  end

  it "checks for valid dates in archive directories" do
    patterns = [['2009-12-23_12:31:10',  true,  'valid'],
                ['2011-03-13_22:02:30',  true,  'valid'],
                ['1992-11-07_02:40:59',  true,  'valid'],
                ['3009-13-23_12:31:10',  false, 'invalid year'],
                ['2009-13-23_12:31:20',  false, 'invalid month'],
                ['2009-12-32_12:31:30',  false, 'invalid day'],
                ['2009-12-23_25:31:40',  false, 'invalid hour'],
                ['2009-13-23_12:63:50',  false, 'invalid minute'],
                ['2009-13-23_12:63:70',  false, 'invalid second'],
                ['09-11-25_12:31:10',    false, 'invalid 2-digit day'],
                ['2009-1-23_12:31:10',   false, 'invalid 1-digit month'],
                ['2009-12-2_12:31:10',   false, 'invalid 1-digit day'],
                ['2009--12-23_12:31:10', false, 'invalid punctuation'],
                ['2009-12--23_12:31:10', false, 'invalid punctuation'],
                ['2009-12-23__12:31:10', false, 'invalid punctuation'],
                ['2009-12-23_12::31:10', false, 'invalid punctuation'],
                ['2009-12-23_12:31::10', false, 'invalid punctuation'],
              ]
    patterns.each {|pattern,expected,reason|
      result = PPCommon.datetimeFormat?(pattern)
      puts "Failed to recognize '#{pattern}' as #{expected ? "valid" : "invalid because of #{reason}"}" unless expected == result
      expected.should == result
    }
  end

  it "creates accurate and properly formatted timestamps" do
    nil while (Time.now.sec == 59) # avoid roll-over related bugs - Clarification?  Huh?!?  I think this may also manifest as a once-in-a-blue-moon loop to infinity, ran the spec and had to CTRL+C it.
    timestamp = PPCommon.newDatetime
    timestamp.length.should == 19
    time = Time.now
    year, month, day, hour, min, sec = timestamp.split(/\D/).collect(&:to_i)
    time.year.should  == year
    time.month.should == month
    time.day.should   == day
    time.hour.should  == hour
    time.min.should   == min
    time.sec.should   == sec
  end

  it "recognizes its own timestamps as valid" do
    PPCommon.datetimeFormat?(PPCommon.newDatetime).should be_true
  end

  it "scans a path, returning it or all files under it" do
    dir = TestLibrary.build_temp_dir
    count = TestLibrary.entries_under(dir).length
    PPCommon.scanBackupDir(dir).length.should == count
  end

  it "excludes specified files during this scan" do
    dir = TestLibrary.build_temp_dir
    files = TestLibrary.entries_under dir
    excludes = 3.of { files.random }.collect {|str| Regexp.new str }
    filtered_files = files.select {|file| excludes.all? {|exclude| file !~ exclude } }
    PPCommon.scanBackupDir(:BackupTarget => dir, :Exclusions => excludes).length.should == filtered_files.length
    filtered_files = files.select {|file| file !~ excludes.first }
    PPCommon.scanBackupDir(:BackupTarget => dir, :Exclusions => excludes.first).length.should == filtered_files.length
  end

  it "makes a backup directory" do
    dir = TestLibrary.mktempdir 'PP-test'
    result = PPCommon.makeBackupDirectory(dir)
    File.directory?(result).should be_true
    PPCommon.makeBackupDirectory(dir).should be_false # non-empty now
  end

  it "turns user-input strings into symbols" do
    PPCommon.symbolize(nil   ).should == :nil
    PPCommon.symbolize(''    ).should == :empty
    PPCommon.symbolize('q'   ).should == :quit
    PPCommon.symbolize('quit').should == :quit
    PPCommon.symbolize('e'   ).should == :edit
    PPCommon.symbolize('edit').should == :edit
    PPCommon.symbolize('y'   ).should == :yes
    PPCommon.symbolize('yes' ).should == :yes
    PPCommon.symbolize('n'   ).should == :no
    PPCommon.symbolize('no'  ).should == :no
    PPCommon.symbolize('fish').should == :fish
    # no real failure case...?
  end

  it "asks a question and returns the response downcased, a default, or throws :quit"  do 
    capture_stdout do
      wrap_input("Blue!\n\n") { PPCommon.ask "What is your favorite colour!?"         }.should == "blue!" 
      wrap_input("\n\n")      { PPCommon.ask "What is your favorite colour!?","BlaCK" }.should == "BlaCK" # default's not downcased
      wrap_io("test\n\n")     { PPCommon.ask "simple question?", "mauve"              }.should == "\nsimple question? " # note extra space
    end
  end 

	it "df should return the expected output in the expected format" do
		PPCommon.df.class.should == Array #Return an array
		PPCommon.df.each {|line| 
			line.length.should == 6		#Each line should have all 6 elements 
		}
	end


	it "expires old backups in backupDest/backup/BackupName according to appropriate expiration policy"

	it "monitors backup destinations to guarantee minimum number of backups available"

end
