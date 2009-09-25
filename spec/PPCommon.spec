#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib"))

require 'PPCommon'

describe PPCommon do
  it "creates an empty temp directory on request" do
    td = PPCommon.mktempdir
    File.exists?(   td).should == true
    File.directory?(td).should == true
  end

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
    patterns = [['2009-12-23_12:31',  true,  'valid'],
                ['2011-03-13_22:02',  true,  'valid'],
                ['1992-11-07_02:40',  true,  'valid'],
                ['3009-13-23_12:31',  false, 'invalid year'],
                ['2009-13-23_12:31',  false, 'invalid month'],
                ['2009-12-32_12:31',  false, 'invalid day'],
                ['2009-12-23_25:31',  false, 'invalid hour'],
                ['2009--13-23_12:63', false, 'invalid minute'],
                ['09-11-25_12:31',    false, 'invalid 2-digit day'],
                ['2009-1-23_12:31',   false, 'invalid 1-digit month'],
                ['2009-12-2_12:31',   false, 'invalid 1-digit day'],
                ['2009--12-23_12:31', false, 'invalid punctuation'],
                ['2009-12--23_12:31', false, 'invalid punctuation'],
                ['2009-12-23__12:31', false, 'invalid punctuation'],
                ['2009-12-23_12::31', false, 'invalid punctuation'],
              ]
    patterns.each {|pattern,expected,reason|
      result = PPCommon.datetimeFormat?(pattern)
      puts "Failed to recognize '#{pattern}' as #{expected ? "valid" : "invalid because of #{reason}"}" unless expected == result
      expected.should == result
    }
  end

  it "scans a path, returning it or all files under it that were not specifically excluded"

end
