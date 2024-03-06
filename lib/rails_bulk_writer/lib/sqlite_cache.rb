module RailsBulkWriter
    module SqliteCache
        class DbRegistry
            include Singleton
            attr_accessor :db_names, :primary_db
            def add_db(name)
                if db_names.include?(name)
                    return false
                else
                    db_names.push(name)

                    new_db = ActiveRecord::DatabaseConfigurations::HashConfig.new(
                        Rails.env, name, configure_cache(name)
                    )
                    dbs.configurations.push(new_db)
                    ActiveRecord::Base.connected_to(database: name.to_sym) do
                        Rake::Task['db:prepare'].invoke
                    end
                end
                true
            end
        end

        def primary_db_config
            dbs = ObjectSpace.each_object(ActiveRecord::DatabaseConfigurations).to_a.first
            primary = dbs.configurations.select{ |i| i.name = (ENV['WRITE_CACHED_DB_NAME'] || 'primary') }
            primary.configuration_hash
        end

        def configure_cache(name)
            # db_info = db.attributes.symbolize_names.slice(:adapter, :encoding, :pool, :timeout, :username, :password, :host, :database)
            
            db_info = {
                adapter: :sqlite3,
                pool: ENV.fetch("RAILS_MAX_THREADS") { 5 },
                timeout: 5000,
                database: "storage/#{name}.sqlite"
            }
            primary_encoding = ENV['WRITE_CACHE_ENCODING'] || primary_db_config[:encoding]
            db_info = db_info.merge(encoding: primary_encoding) if primary_encoding.present?
        end

        def generate_cache_db
            i = 1
            name = "write_cache_#{i}"
            while add_db(db_name) == false
                # kee trying until it finds one that is not taken
                i += 1
                name = "write_cache_#{i}"
            end

            return name
        end

        module_function :generate_cache_db
    end
end