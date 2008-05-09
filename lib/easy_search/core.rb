%w(constants errors setup validations).each do |f| 
  require File.join(File.dirname(__FILE__), f)
end

module RPH
  module EasySearch
    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
      
      # before continuing, validate that the models identified (if any) in the 
      # setup_tables block (within `Setup.config') exist and are valid ActiveRecord descendants
      Validations.validate_settings!
    end
    
    module ClassMethods
      # "Search.users" translates to "User.find" dynamically
      def method_missing(name, *args)
        # instantiate a new instance of self with
        # the @klass set to the missing method
        self.new(name.to_sym)
      end
    end
    
    module InstanceMethods
      def initialize(klass)
        @klass = klass
        
        # validate that the class derived from the missing method descends from
        # ActiveRecord and has been "configured" in `Setup.config { setup_tables {...} }'
        # (i.e. "Search.userz.with(...)" where "userz" is an invalid model)
        Validations.validate_class!(@klass)
      end
      
      # used to collect/parse the keywords that are to be searched, and return
      # the search results (hands off to the Rails finder)
      #
      # Example:
      #   Search.users.with("ryan heath")
      #   # => <#User ... > or []
      def with(keywords, options={})
        keywords = extract(keywords)
        search_terms = (keywords.collect { |k| k.downcase } - Setup.dull_keywords.collect { |k| k.downcase })
        return [] if search_terms.blank?
        
        klass = to_model(@klass)
        sanitized_sql_conditions = klass.send(:sanitize_sql_for_conditions, build_conditions_for(search_terms))
        klass.find(:all, :select => "DISTINCT #{@klass.to_s}.*", :conditions => sanitized_sql_conditions, :order => options[:order], :limit => options[:limit])
      end
      
      private
        # constructs the conditions for the WHERE clause in the SQL statement.
        # (compares each search term against each configured column for that model)
        #
        # ultimately this allows for a single query rather than several small ones,
        # alleviating the need to open/close DB connections and instantiate multiple
        # ActiveRecord objects through the loop
        #
        # it should be noted that a search with too many keywords against too many columns
        # in a DB with too many rows will inevitably hurt performance (use ultrasphinx!)
        def build_conditions_for(terms)
          returning([]) do |clause|
            Setup.table_settings[@klass].each do |column|
              terms.each do |term|
                if to_model(@klass).columns.map(&:name).include?(column.to_s)
                  clause << "`#{@klass}`.`#{column}` LIKE '%#{term}%'"
                end
              end
            end
          end.join(" OR ")
      	end    	  
        
        # using scan(/\w+/) to parse the words
        #
        # emails were being separated (split on the "@" symbol since it's not a word) 
        # so "rheath@test.com" became ["rheath", "test.com"] as search terms, when we 
        # really want to keep emails intact. as a work around, the emails are pulled out before 
        # the words are scanned, then each email is pushed back into the array as its own criteria.
        #
        # TODO: refactor this method to be less complex for such a simple problem.
        def extract(terms)
          terms.gsub!("'", "")
          emails = strip_emails_from(terms)
          
          unless emails.blank?            
            emails.inject(terms.gsub(RegExp::EMAIL, '').scan(/\w+/)) { |t, email| t << email }
          else
            terms.scan(/\w+/)
          end
      	end
             
        # extracts the emails from the keywords
        def strip_emails_from(text)
      	  text.split.reject { |t| t.match(RegExp::EMAIL) == nil }
      	end
      	
      	# converts the symbol representation of a table to an actual ActiveRecord model
      	def to_model(klass)
      	  klass.to_s.singularize.classify.constantize
      	end
    end
  end
end