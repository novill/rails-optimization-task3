# Наивная загрузка данных из json-файла в БД
# rake reload_json[fixtures/small.json]

desc 'Очистка запросов в pg_hero'
task :empty_pghero_query_stats => :environment do
  # puts ActiveRecord::Base.connection.execute('delete from pg_statements').inspect
  puts ActiveRecord::Base.connection.execute('delete from pghero_query_stats').inspect
end

desc 'Загрузка данных из файла'
task :reload_json, [:file_name] => :environment do |_task, args|
  json = Oj.load(File.read(args.file_name))
  ActiveRecord::Base.transaction do
    City.delete_all
    Bus.delete_all
    Service.delete_all
    Trip.delete_all
    ActiveRecord::Base.connection.execute('delete from buses_services;')
    trips_array  = []

    json.each_with_index do |trip, index|

      from = City.find_cached_or_create(trip['from'])
      to = City.find_cached_or_create(trip['to'])
      bus = Bus.find_cached_or_create(trip['bus'])

      trip_hash = {
        from_id: from.id,
        to_id: to.id,
        bus_id: bus.id,
        start_time: trip['start_time'],
        duration_minutes: trip['duration_minutes'],
        price_cents: trip['price_cents']
      }
      trips_array << trip_hash
      if index%1000 == 999
        Trip.import(trips_array)
        trips_array =[]
      end
    end
    Trip.import(trips_array)
  end
end
