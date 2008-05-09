require File.join(File.dirname(__FILE__), 'spec_helper')

# Note: these specs mainly cover exception handling and the
#       expected outcome of the configuration/settings. To 
#       really test the functionality, once installed in an
#       application, specs should be written that directly
#       relate to the models of the application.

# config according to sample models specified in spec_helper
RPH::EasySearch::Setup.config do
  users    :first_name, :last_name, :email
  projects :title, :description
  groups   :name, :description
end

describe "EasySearch" do  
  it "Search class should have EasySearch functionality" do
    Search.included_modules.include?(RPH::EasySearch).should be_true
  end
  
  it "should override initialize to expect a class name attr" do
    Search.new rescue ArgumentError; true
  end
  
  it "should return blank search results (an empty array) for missing keywords" do
    results = Search.users.with('')
    results.should be_an_instance_of(Array)
    results.should be_empty
  end
  
  describe "Setup.config" do
    before(:each) do      
      @settings = RPH::EasySearch::Setup.settings
    end
    
    it "should return nil if no block is given" do
      config = RPH::EasySearch::Setup.config
      config.should be_nil
    end
        
    it "should have three models in EasySearch configuration" do
      @settings.keys.size.should eql(3)
    end
    
    it "should have keys mapped to plural versions of model names" do
      @settings.keys.include?('users').should be_true
      @settings.keys.include?('projects').should be_true
      @settings.keys.include?('groups').should be_true
    end
    
    it "should have indifferent access to tables/columns in Setup.settings hash" do
      @settings.should be_an_instance_of(HashWithIndifferentAccess)
      @settings[:users].should eql(@settings['users'])
      @settings[:projects].should eql(@settings['projects'])
      @settings[:groups].should eql(@settings['groups'])
    end
    
    it "should have the correct number of columns for each table name" do
      @settings[:users].size.should eql(3)
      @settings[:projects].size.should eql(2)
      @settings[:groups].size.should eql(2)
    end
    
    it "should have instances of Array as the values in the Setup.settings hash" do
      @settings[:users].should be_an_instance_of(Array)
      @settings[:projects].should be_an_instance_of(Array)
      @settings[:groups].should be_an_instance_of(Array)
    end
    
    it "should specify :first_name, :last_name, :email as the columns to search for 'users' table" do
      @settings[:users].include?(:first_name).should be_true
      @settings[:users].include?(:last_name).should be_true
      @settings[:users].include?(:email).should be_true
    end
    
    it "should specify :title, :description as the columns to search for 'projects' table" do
      @settings[:projects].include?(:title).should be_true
      @settings[:projects].include?(:description).should be_true
    end
    
    it "should specify :name, :description as the columns to search for 'groups' table" do
      @settings[:groups].include?(:name).should be_true
      @settings[:groups].include?(:description).should be_true
    end
  end
  
  describe "removing dull keywords" do
    EZS = RPH::EasySearch
    
    after(:each) do
      # reset dull keywords to defaults
      EZS::Setup.strip_keywords(true) { EZS::DEFAULT_DULL_KEYWORDS }
    end
    
    it "should have default dull keywords" do
      EZS::Setup.dull_keywords.should eql(EZS::DEFAULT_DULL_KEYWORDS)
    end
    
    it "should be an instance of Array" do
      EZS::Setup.dull_keywords.should be_an_instance_of(Array)
    end
    
    it "should support adding new dull keywords to the list" do
      more_dull_keywords = ['something', 'else']
      EZS::Setup.strip_keywords { more_dull_keywords }
      
      EZS::Setup.dull_keywords.should eql(EZS::DEFAULT_DULL_KEYWORDS + more_dull_keywords)
    end
    
    it "should support overwriting the dull keywords completely" do
      new_dull_keywords = ['whatever', 'i', 'want']
      EZS::Setup.strip_keywords(true) { new_dull_keywords }
      
      EZS::Setup.dull_keywords.should eql(new_dull_keywords)
    end
    
    it "should not have duplicate dull keywords" do
      duplicate_default_keywords = EZS::DEFAULT_DULL_KEYWORDS
      EZS::Setup.strip_keywords { duplicate_default_keywords }
      
      EZS::Setup.dull_keywords.should eql(EZS::DEFAULT_DULL_KEYWORDS)
    end
  end
  
  describe "errors" do    
    it "should raise NoModelError if a model (constant) cannot be found" do
      RPH::EasySearch::Setup.config { wrong :first, :last }
      Search.send(:include, RPH::EasySearch) rescue RPH::EasySearch::NoModelError; true
    end
    
    it "should raise InvalidActiveRecordModel error if model doesn't descend from ActiveRecord" do
      Search.new(:wrong) rescue RPH::EasySearch::InvalidActiveRecordModel; true
    end
    
    it "should raise InvalidActiveRecordModel error if constant/model doesn't exist" do
      Search.whatever.with("wrong") rescue RPH::EasySearch::InvalidActiveRecordModel; true
    end
    
    it "should raise InvalidSettings error if there are no specified columns for a given model" do
      class Sample < ActiveRecord::Base; end
      Search.sample.with("something") rescue RPH::EasySearch::InvalidSettings; true
    end
  end
end