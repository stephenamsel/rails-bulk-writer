# Pre-Alpha

This is still under construction. IT does not yet have proper testing.

It will be published if and when the author has been able to test it and has time to manage a collaboration.

# RailsBulkWriter

The RailsBulkWriter Gem is meant to replace individual SQL queries to the primary DB with bulk queries
while allowing the Rails developer to write code normally. It works by creating local SQLite DBs 
on the Rails server, 1 per thread, saving all data there, sending the to the primary DB
just before it would be Committed, and then truncating the caching DB
to be reused in the next Transaction on that Thread.

With the SQLite DB being local, the write-queries do not have to run over any network, which normally reduces latency greatly. Also, these Write-cache DBs will scale horizontally with the webservers.

When used in a Job or endpoint that saves a large amount of data, this should
1. drastically reduce the load on the primary SQL database, typically the most difficult part of a system to scale
2. reduce latency
3. not affect execution of callbacks or other business logic of the server
4. not generate new racing conditions

It should be noted that this may pair very well with the kafka_intake gem and its related infrastructure
that bundles a large number of requests into a single Job.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rails_bulk_writer

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rails_bulk_writer

## Usage

Install the Gem and proceed normally with Rails. It should be mostly transparent to developers outside of the issues listed below.

1. Avoid using Bulk insert / update / delete. This is handled for you.
2. Until just before the Commit, Writes are sent to the local Cache while Reads are drawn from the database. If you must read from tables to which you have written and may be selecting records you have edited during this transaction, use Nested SQL rather than Joins to get related records if you have created new records or modified any relevant foreign keys.
3. For now, HABTM relations are not included in this. Those would be written directly to the primary database normally, and may encounter Foreign Key Constraint errors if written before their related records are created there. This is the next issue to be addressed in this Gem. In the meantime, it may be better to build models for joins-tables and use paired `has_many ... :through ...` relations.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

The original author does not currently have time to manage a collaboration. Should that change, new information will be entered here.
<!---
Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_bulk_writer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rails_bulk_writer/blob/master/CODE_OF_CONDUCT.md).
--->

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RailsBulkWriter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rails_bulk_writer/blob/master/CODE_OF_CONDUCT.md).
