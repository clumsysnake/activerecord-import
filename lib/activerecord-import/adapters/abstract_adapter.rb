module ActiveRecord::Import::AbstractAdapter
  module InstanceMethods
    def next_value_for_sequence(sequence_name)
      %{#{sequence_name}.nextval}
    end

    def insert_many( sql, values, *args ) # :nodoc:
      number_of_inserts = 1

      base_sql,post_sql = if sql.is_a?( String )
        [ sql, '' ]
      elsif sql.is_a?( Array )
        [ sql.shift, sql.join( ' ' ) ]
      end

      sql2insert = base_sql + values.join( ',' ) + post_sql
      insert( sql2insert, *args )

      [number_of_inserts,[]]
    end

    def pre_sql_statements(options)
      sql = []
      sql << options[:pre_sql] if options[:pre_sql]
      sql << options[:command] if options[:command]
      sql << "IGNORE" if options[:ignore]

      #add keywords like IGNORE or DELAYED
      if options[:keywords].is_a?(Array)
        sql.concat(options[:keywords])
      elsif options[:keywords]
        sql << options[:keywords].to_s
      end

      sql
    end

    # Synchronizes the passed in ActiveRecord instances with the records in
    # the database by calling +reload+ on each instance.
    def after_import_synchronize( instances )
      instances.each { |e| e.reload }
    end

    # Returns an array of post SQL statements given the passed in options.
    def post_sql_statements( table_name, options ) # :nodoc:
      post_sql_statements = []

      if supports_on_duplicate_key_update?
        if options[:on_duplicate_key_ignore] && respond_to?(:sql_for_on_duplicate_key_ignore)
          post_sql_statements << sql_for_on_duplicate_key_ignore( table_name, options[:on_duplicate_key_ignore] )
        elsif options[:on_duplicate_key_update]
          post_sql_statements << sql_for_on_duplicate_key_update( table_name, options[:on_duplicate_key_update] )
        end
      end

      #custom user post_sql
      post_sql_statements << options[:post_sql] if options[:post_sql]

      #with rollup
      post_sql_statements << rollup_sql if options[:rollup]

      post_sql_statements
    end

    # Returns the maximum number of bytes that the server will allow
    # in a single packet
    def max_allowed_packet
      NO_MAX_PACKET
    end

    def supports_on_duplicate_key_update?
      false
    end
  end
end
