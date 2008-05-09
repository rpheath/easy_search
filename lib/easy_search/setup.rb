module RPH
  module EasySearch
    class Setup
      class << self
        # accepts a block that specifies the columns
        # to search for each model
        #
        # Example:
        #   Setup.config do
        #     users    :first_name, :last_name, :email
        #     projects :title, :description
        #   end
        def config(&block)
          return nil unless block_given?
          self.class_eval(&block)
          self.settings
        end
        
        # allows customization of the dull_keywords setting
        # (can be overwritten or appended)
        #
        # Example:
        #   DEFAULT_DULL_KEYWORDS = ['the', 'and', 'is']
        # 
        #  1) appending keywords to the default list
        #     Setup.strip_keywords do
        #       ['it', 'why', 'is']
        #     end
        #
        #     $> Setup.dull_keywords
        #     $> => ['the', 'and', 'it', 'why', 'is']
        #
        #  2) overwriting existing keywords
        #     Setup.strip_keywords(true) do
        #       ['something', 'whatever']
        #     end
        #
        #     $> Setup.dull_keywords
        #     $> => ['something', 'whatever']
        def strip_keywords(overwrite=false, &block)
          return nil unless block_given?
          raise(InvalidDullKeywordsType, InvalidDullKeywordsType.message) unless block.call.is_a?(Array)
          
          overwrite ? @@dull_keywords = block.call : @@dull_keywords = (self.dull_keywords << block.call)
          self.dull_keywords
        end
        # returns a hash with the key as the models to be searched
        # and the value as an array of columns for that model
        #
        # Example:
        #   $> Setup.settings
        #   $> => {"users"=>[:first_name, :last_name, :email], "projects"=>[:title, :description]}
        def settings
          @@settings ||= HashWithIndifferentAccess.new
        end
        
        # returns an array of keywords that serve as no benefit in a search
        #
        # Example:
        #   $> Setup.dull_keywords
        #   $> => ['a', 'and', 'but', 'the', ...]
        def dull_keywords
          (@@dull_keywords ||= DEFAULT_DULL_KEYWORDS).flatten.uniq
        end
        
        # this is the magic that makes `Setup.config' work like it does.
        # once the block is eval'd those missing methods (i.e. "users" and "projects")
        # will be passed here and the settings hash will be updated with the
        # key set to the table, and the value set to the columns. this allows the
        # EasySearch plugin to work generically for any code base.
        def method_missing(table, *fields)
          settings[table] = fields
        end
      end
    end
  end
end