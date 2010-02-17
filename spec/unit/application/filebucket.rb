#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/application/filebucket'

describe "Filebucket" do
  before :each do
    @filebucket = Puppet::Application[:filebucket]
  end

  it "should ask Puppet::Application to not parse Puppet configuration file" do
    @filebucket.should_parse_config?.should be_false
  end

  it "should declare a get command" do
    @filebucket.should respond_to(:get)
  end

  it "should declare a backup command" do
    @filebucket.should respond_to(:backup)
  end

  it "should declare a restore command" do
    @filebucket.should respond_to(:restore)
  end

  [:bucket, :debug, :local, :remote, :verbose].each do |option|
    it "should declare handle_#{option} method" do
      @filebucket.should respond_to("handle_#{option}".to_sym)
    end

    it "should store argument value when calling handle_#{option}" do
      @filebucket.options.expects(:[]=).with("#{option}".to_sym, 'arg')
      @filebucket.send("handle_#{option}".to_sym, 'arg')
    end
  end

  describe "during setup" do

    before :each do
      Puppet::Log.stubs(:newdestination)
      Puppet.stubs(:settraps)
      Puppet::Log.stubs(:level=)
      Puppet.stubs(:parse_config)
      Puppet::Network::Client.dipper.stubs(:new)
      @filebucket.options.stubs(:[]).with(any_parameters)
    end


    it "should set console as the log destination" do
      Puppet::Log.expects(:newdestination).with(:console)

      @filebucket.run_setup
    end

    it "should trap INT" do
      @filebucket.expects(:trap).with(:INT)

      @filebucket.run_setup
    end

    it "should set log level to debug if --debug was passed" do
      @filebucket.options.stubs(:[]).with(:debug).returns(true)

      Puppet::Log.expects(:level=).with(:debug)

      @filebucket.run_setup
    end

    it "should set log level to info if --verbose was passed" do
      @filebucket.options.stubs(:[]).with(:verbose).returns(true)

      Puppet::Log.expects(:level=).with(:info)

      @filebucket.run_setup
    end

    it "should Parse puppet config" do
      Puppet.expects(:parse_config)

      @filebucket.run_setup
    end

    it "should print puppet config if asked to in Puppet config" do
      @filebucket.stubs(:exit)
      Puppet.settings.stubs(:print_configs?).returns(true)

      Puppet.settings.expects(:print_configs)

      @filebucket.run_setup
    end

    it "should exit after printing puppet config if asked to in Puppet config" do
      Puppet.settings.stubs(:print_configs?).returns(true)

      lambda { @filebucket.run_setup }.should raise_error(SystemExit)
    end

    describe "with local bucket" do

      before :each do
        @filebucket.options.stubs(:[]).with(:local).returns(true)
      end

      it "should create a client with the default bucket if none passed" do
        Puppet.stubs(:[]).with(:bucketdir).returns("path")

        Puppet::Network::Client::Dipper.expects(:new).with { |h| h[:Path] == "path" }

        @filebucket.run_setup
      end

      it "should create a local Client dipper with the given bucket" do
        @filebucket.options.stubs(:[]).with(:bucket).returns("path")

        Puppet::Network::Client::Dipper.expects(:new).with { |h| h[:Path] == "path" }

        @filebucket.run_setup
      end

    end

    describe "with remote bucket" do

      it "should create a remote Client to the configured server" do
        Puppet.stubs(:[]).with(:server).returns("puppet.reductivelabs.com")

        Puppet::Network::Client::Dipper.expects(:new).with { |h| h[:Server] == "puppet.reductivelabs.com" }

        @filebucket.run_setup
      end

    end

  end

  describe "when running" do

    before :each do
      Puppet::Log.stubs(:newdestination)
      Puppet.stubs(:settraps)
      Puppet::Log.stubs(:level=)
      Puppet.stubs(:parse_config)
      Puppet::Network::Client.dipper.stubs(:new)
      @filebucket.options.stubs(:[]).with(any_parameters)

      @client = stub 'client'
      Puppet::Network::Client::Dipper.stubs(:new).returns(@client)

      @filebucket.run_setup
    end

    it "should use the first non-option parameter as the dispatch" do
      ARGV.stubs(:shift).returns(:get)

      @filebucket.get_command.should == :get
    end

    describe "the command get" do

      before :each do
        @filebucket.stubs(:print)
      end

      it "should call the client getfile method" do
        @client.expects(:getfile)

        @filebucket.get
      end

      it "should call the client getfile method with the given md5" do
        md5="DEADBEEF"
        ARGV.stubs(:shift).returns(md5)

        @client.expects(:getfile).with(md5)

        @filebucket.get
      end

      it "should print the file content" do
        @client.stubs(:getfile).returns("content")

        @filebucket.expects(:print).returns("content")

        @filebucket.get
      end

    end

    describe "the command backup" do
      it "should call the client backup method for each given parameter" do
        @filebucket.stubs(:puts)
        FileTest.stubs(:exists?).returns(true)
        FileTest.stubs(:readable?).returns(true)
        ARGV.stubs(:each).multiple_yields("file1","file2")

        @client.expects(:backup).with("file1")
        @client.expects(:backup).with("file2")

        @filebucket.backup
      end
    end

    describe "the command restore" do
      it "should call the client getfile method with the given md5" do
        md5="DEADBEEF"
        file="testfile"
        ARGV.stubs(:shift).returns(file,md5)

        @client.expects(:restore).with(file,md5)

        @filebucket.restore
      end
    end

  end


end
