# MapBuilder.rb - a ruby wrapper to generate code for the mapstraction
# library. Written by Darcy R. Laycock

# Released under an MIT License, Copyright Yut Media Inc.

# Note: I'm tempted to use method missing etc
# but it's already starting to feel 'dirty'

class MapBuilder
  Point = Struct.new(:lat, :lng)
  
  attr_accessor :js_array
  
  def initialize(div_name, provider = 'google')
    @js_array = []
    does { var(:mapstraction).is new(:Mapstraction, div_name, provider.to_s) }
  end
  
  def add_point(*args)
    opts  = args.extract_options!
    point = extract_coordinates(args)
    
    does        { var(:point).is new(:LatLonPoint, point.lat, point.lng) }
    followed_by { var(:marker).is new(:Marker, var(:point)) }
    followed_by { var(:marker).calls :setInfoBubble, escape_javascript(opts[:message].to_s) } if opts.has_key?(:message)
    followed_by { var(:mapstraction).calls :addMarker, var(:marker) }
  end
  
  def auto_fit
    does { var(:mapstraction).calls :autoCenterAndZoom }
  end
  
  def new_map
    point = Point.new(1.0, 1.0)
    does { var(:point).is new(:LatLonPoint, point.lat, point.lng) }
  end
  
  def set_zoom_and_center(zoom, *args)
    point = extract_coordinates(args)
    does        { var(:point).is new(:LatLonPoint, point.lat, point.lng) }
    followed_by { var(:mapstraction).calls :setCenterAndZoom, var(:point), zoom.to_i }
  end
  
  def to_js
    self.js_array * "\n"
  end
  
  def inspect
    "#<MapBuilder:0x#{self.object_id.to_s(16)} #{self.js_array.size} lines of js>"
  end
  
  private
  
  class JSVar
    attr_accessor :name
    
    def initialize(name, parent)
      self.name = name
      @parent = parent
    end
    
    def to_json
      self.name.to_s
    end
    
    def is(value)
      "var #{name} = #{value.to_s};"
    end
    
    def calls(method, *args)
      @parent.send(:call, method, *args)
    end
    
  end
  
  def var(name)
    JSVar.new(name, self)
  end
  
  def new(klass, *vars)
    "new #{klass.to_s.strip}(#{prepare_js_args(vars)})"
  end
  
  def escape_javascript(javascript)
    (javascript || '').gsub('\\','\0\0').gsub('</','<\/').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end
  
  def call(name, *args)
    "#{name.to_s.strip}(#{prepare_js_args(args)});"
  end
  
  def append_javascript(val)
    self.js_array << val
  end
  
  def does(&blk)
    value = blk.call
    value << ";" unless value.strip.ends_with?(";")
    append_javascript value
    return self
  end
  
  alias followed_by does
  
  def prepare_js_args(args = [])
    return args.compact.map { |a| a.to_json }.join(", ")
  end
  
  def extract_coordinates(args)
    if args.first.respond_to?(:lat) && args.first.respond_to?(:lng)
      return Point.new(args.first.lat.to_f, args.first.lng.to_f)
    else
      return Point.new(*args[0..1].map(&:to_f))
    end
  end
  
end