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
    nil while (Time.now.sec == 59) # avoid roll-over related bugs
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
    PPCommon.symbolize(nil).should == :nil
    PPCommon.symbolize('').should == :empty
    PPCommon.symbolize('q').should == :quit
    PPCommon.symbolize('quit').should == :quit
    PPCommon.symbolize('e').should == :edit
    PPCommon.symbolize('edit').should == :edit
    PPCommon.symbolize('y').should == :yes
    PPCommon.symbolize('yes').should == :yes
    PPCommon.symbolize('n').should == :no
    PPCommon.symbolize('no').should == :no
  end
end
