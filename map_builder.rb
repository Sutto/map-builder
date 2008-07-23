class MapBuilder
  
  attr_accessor :js_array
  
  def initialize(div_name, provider = 'google')
    @js_array = []
    call_function "var mapstraction = new Mapstraction", div_name, provider.to_s
  end
  
  def add_point(*args)
    opts = args.extract_options!
    point = extract_coordinates(args)
    call_function "var point = new LatLonPoint", point.lat, point.lng
    call_function "var marker = new Marker", JSVar.new(:point)
    if opts.has_key?(:message)
      message = opts[:message].to_s
      call_function "marker.setInfoBubble", escape_javascript(message)
    end
    call_function "mapstraction.addMarker", JSVar.new(:marker)
  end
  
  def auto_fit
    call_function "mapstraction.autoCenterAndZoom"
  end
  
  def set_centre_and_zoom(zoom, *args)
    point = extract_coordinates(args)
    call_function "var point = new LatLonPoint", point.lat, point.lng
    call_function "mapstraction.setCenterAndZoom", JSVar.new(:point), zoom.to_i
  end
  
  def to_js
    self.js_array * "\n"
  end
  
  private
  
  class LLPoint
    attr_accessor :lat, :lng
    
    def initialize(lat, lng)
      self.lat = lat
      self.lng = lng
    end
  end
  
  class JSVar
    attr_accessor :name
    
    def initialize(name)
      self.name = name
    end
    
    def to_json
      self.name.to_s
    end
  end
  
  def escape_javascript(javascript)
    (javascript || '').gsub('\\','\0\0').gsub('</','<\/').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end
  
  def call_function(name, *args)
    append_javascript "#{name.strip}(#{prepare_js_args(args)});"
  end
  
  def assign_variable(name, value)
    append_javascript "var #{name.to_s} = #{value};"
  end
  
  def append_javascript(val)
    self.js_array << val
  end
  
  def prepare_js_args(args = [])
    return args.compact.map { |a| a.to_json }.join(", ")
  end
  
  def extract_coordinates(args)
    if args.first.respond_to?(:lat) && args.first.respond_to?(:lng)
      return LLPoint.new(args.first.lat.to_f, args.first.lng.to_f)
    else
      return LLPoint.new(*args[0..1].map(&:to_f))
    end
  end
  
end