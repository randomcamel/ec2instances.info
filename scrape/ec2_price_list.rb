#!/usr/bin/env ruby

require "rubygems"
require "json"
require "pp"

# The pricing and instance-types pages appear to have been built by different teams. The pricing page doesn't
# use the API names for instance types, instead using...these things. In a <select> called 'ec2Dictionary'.

API_SIZES = {
  "u"         => "micro",
  "sm"        => "small",
  "m"         => "medium",
  "med"       => "medium",
  "lg"        => "large",
  "xl"        => "xlarge",
  "xxl"       => "2xlarge",
  "xxxxl"     => "4xlarge",
  "xxxxxxxxl" => "8xlarge",
}

API_TYPES = {
  "hiCPUODI"        => "c1",
  "clusterComputeI" => "cc1",
  "clusterGPUI"     => "cg1",
  "clusterHiMemODI" => "cr1",
  "hiIoODI"         => "hi1",
  "hiStoreODI"      => "hs1",
  "stdODI"          => "m1",
  "hiMemODI"        => "m2",
  "secgenstdODI"    => "m3",
  "uODI"            => "t1",
}

REGION_NAMES = {
  "us-east"    => "us-east-1",
  "us-west-2"  => "us-west-2",
  "us-west"    => "us-west-1",
  "eu-ireland" => "eu-west-1",
  "apac-tokyo" => "ap-northeast-1",
  "apac-sin"   => "ap-southeast-1",
  "apac-syd"   => "ap-southeast-2",
  "sa-east-1"  => "sa-east-1",
}

def check_exists(hash, key)
  unless hash.has_key?(key)
    warn "Couldn't find key '#{key}'"
  end
end

class Ec2PriceList

  attr_accessor :label, :regions

  def initialize(filepath, list_label=nil)
    @label = list_label || filename.sub(".json", "")
    json_data = JSON.load(File.new(filepath))
    @regions = extract_region_data(json_data)
  end

  def convert_to_api_types(type_struct)
    weird_type = type_struct["type"]
    check_exists(API_TYPES, weird_type)
    type_struct["type"] = API_TYPES[weird_type]

    type_struct["sizes"].each do |size_entry|
      weird_size = size_entry["size"]
      check_exists(API_SIZES, weird_size)
      size_entry["size"] = API_SIZES[weird_size]
    end
  end

  def flatten_price_list(type_struct)
    flattened = {}

    kind = type_struct["type"]
    type_struct["sizes"].each do |size_data|
      size = size_data["size"]
      api_name = "#{kind}.#{size}"
      flattened[api_name] = {
        :os => size_data["valueColumns"][0]["name"],
        :price_usd => size_data["valueColumns"][0]["prices"]["USD"]
      }
    end

    flattened
  end

  def extract_region_data(json_data)
    regions = {}
    json_data["config"]["regions"].each do |region_struct|
      name = region_struct["region"]
      api_name = REGION_NAMES[name]
      regions[api_name] = region_struct["instanceTypes"]
    end

    regions.keys.each do |region_name|
      flat_prices = {}
      regions[region_name].each do |instance_type|
        convert_to_api_types(instance_type)
        flat_prices.merge!(flatten_price_list(instance_type))
      end
      regions[region_name] = flat_prices
    end
    regions
  end
end

if __FILE__ == $0
  linux = Ec2PriceList.new("json_data/linux-od.json", "Linux")
  pp linux.regions["us-east-1"]
end
