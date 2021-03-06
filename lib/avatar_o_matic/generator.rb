require 'mini_magick'

#
# generator = AvatarOMatic::Generator.new(...)
# generator.generate!   Does the magick, returns itself
# generator.save(path)  Saves the image to path
# generator.image       Returns the underlying minimagick object
#
# AvatarOMatic::Generator.new.generate!.save(path)
#


module AvatarOMatic
  class Generator

    attr_accessor :size
    attr_reader :image

    def initialize(opts={})
      super()

      opts.keys.select {|k| (Config.properties + [:size]).include? k }.each do |opt|
        self.send :"#{opt}=", opts[opt]
      end

      @size ||= 400
    end

    def type=(type)
      unless Config.types.include? type.to_sym
        raise InvalidPropertyError.new("#{type} is not a recognised type")
      end
      @type = type
    end

    def type
      @type ||= Config.types.sample
    end


    Config.properties.each do |prop|
      define_method :"#{prop}=" do |value|
        allowed_size = Config.options_for(type, prop).size

        if value > allowed_size
          raise InvalidPropertyError.new "There are only #{allowed_size} options for #{prop} (#{type}), you wanted #{value}"
        end

        instance_variable_set :"@#{prop}", value
      end

      define_method :"#{prop}" do
        value = instance_variable_get :"@#{prop}"

        unless value
          value = Random.new.rand Config.options_for(type, prop).size
          instance_variable_set :"@#{prop}", value
        end

        value
      end
    end

    def generate!
      @image = MiniMagick::Image.open path_for :background

      Config.properties.select {|p| p != :background }.each do |prop|
        overlay = MiniMagick::Image.open path_for prop
        @image = @image.composite(overlay) do |c|
          c.compose 'Over'
        end
      end

      @image.resize size if image.width != size

      self
    end

    def save(path)
      raise NoImageYetError.new if @image.nil?
      @image.write path
      path
    end

    private

    def option(prop)
      self.send prop.to_sym
    end

    def path_for(prop)
      Config.options_for(type, prop)[option prop]
    end
  end

  class InvalidPropertyError < StandardError; end
  class NoImageYetError < StandardError; end
end