#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'geoutm'
require 'date'
require 'kafka'

@name = "gijonbus2k"
@utmzone = ENV['UTMZONE'].nil? ? "30T" : ENV['UTMZONE']
@zone = ENV['ZONE'].nil? ? "CEST" : ENV['ZONE']
url = ENV['URL'].nil? ? "http://datos.gijon.es/doc/transporte/busgijontr.json" : ENV['URL']
@time = ENV['TIME'].nil? ? 10 : ENV['TIME']
kafka_broker = ENV['KAFKA_BROKER'].nil? ? "127.0.0.1" : ENV['KAFKA_BROKER']
kafka_port = ENV['KAFKA_PORT'].nil? ? "9092" : ENV['KAFKA_PORT']
kafka_topic = ENV['KAFKA_TOPIC'].nil? ? "gijonbus" : ENV['KAFKA_TOPIC']
kclient = Kafka.new(seed_brokers: ["#{kafka_broker}:#{kafka_port}"], client_id: "gijonbus2k")

def w2k(url,kclient)
    lastasset = {}
    lastdigest = ""
    puts "[#{@name}] Starting gijonbus poc thread"
    while true
        begin
            puts "[#{@name}] Connecting to #{url}" unless ENV['DEBUG'].nil?
            busjson = Net::HTTP.get(URI(url))
            next if lastdigest == Digest::MD5.hexdigest(busjson)
            bushash = JSON.parse(busjson)
            bushash["posiciones"]["posicion"].each do |bus|
                timestamp = DateTime.parse("#{Date.parse(bus["fechaactualizacion"]).to_s}T#{bus["horaactualizacion"]} #{@zone}").to_time.to_i
                unless lastasset["#{bus["idautobus"]}"].nil?
                    next if lastasset["#{bus["idautobus"]}"] == timestamp
                end
                lastasset["#{bus["idautobus"]}"] = timestamp
                puts "New data from bus_id: #{bus["idautobus"]}, timestamp: #{timestamp}" unless ENV['DEBUG'].nil?
                bus["timestamp"] = timestamp
                coord = GeoUtm::UTM.new @utmzone,bus["utmx"],bus["utmy"], GeoUtm::Ellipsoid::WGS84
                bus["latitude"] = "#{coord.to_lat_lon.lat}"
                bus["longitude"] = "#{coord.to_lat_lon.lon}"
                #puts "bus asset: #{JSON.pretty_generate(bus)}\n" unless ENV['DEBUG'].nil?
                kclient.deliver_message("#{bus.to_json}",topic: "gijonbus")
            end

            sleep @time
        rescue Exception => e
            puts "Exception: #{e.message}"

        end
    end

end


Signal.trap('INT') { throw :sigint }

catch :sigint do
        t1 = Thread.new{w2k(url,kclient)}
        t1.join
end

puts "Exiting from gijonbus2k"

## vim:ts=4:sw=4:expandtab:ai:nowrap:formatoptions=croqln:
