module RPH
  module EasySearch
    # module to hold any regexp constants when dealing with
    # search terms
    module RegExp
      EMAIL = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6})/
    end
    
    # these keywords will be removed from any search terms, as they
    # provide no value and just increase the size of the query.
    # (the idea is a small attempt to be as efficient as possible)
    DEFAULT_DULL_KEYWORDS = ['a', 'the', 'and', 'but', 'or', 'so', 'what']
  end
end