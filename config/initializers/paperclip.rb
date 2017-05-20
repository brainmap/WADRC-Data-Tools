#/config/initializers/paperclip.rb
require 'paperclip/geometry_detector_factory'
require 'paperclip/thumbnail'
 
# not really fix anything--- Chuck 20170314
# HACK: Monkey patch to remove `[0]` from the end of filename.
#       Actual until https://github.com/thoughtbot/paperclip/issues/2223
# rubocop:disable all
module Paperclip
  class GeometryDetector
    private

    def geometry_string
      orientation = Paperclip.options[:use_exif_orientation] ? '%[exif:orientation]' : '1'
      Paperclip.run('identify',
                    "-format '%wx%h,#{orientation}' :file", { file: path.to_s }, swallow_stderr: true)
    rescue Cocaine::ExitStatusError
      ''
    rescue Cocaine::CommandNotFoundError
      raise_because_imagemagick_missing
    end
  end
end

module Paperclip
  # Handles thumbnailing images that are uploaded.
  class Thumbnail < Processor
    def make
      src = @file
      filename = [@basename, @format ? ".#{@format}" : ""].join
      dst = TempfileFactory.new.generate(filename)

      begin
        parameters = []
        parameters << source_file_options
        parameters << ":source"
        parameters << transformation_command
        parameters << convert_options
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        success = convert(parameters, source: "#{File.expand_path(src.path)}", dest: File.expand_path(dst.path))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error processing the thumbnail for #{@basename}" if @whiny
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      dst
    end

    protected

    def identified_as_animated?
      if @identified_as_animated.nil?
        @identified_as_animated = ANIMATED_FORMATS.include? identify("-format %m :file", file: "#{@file.path}").to_s.downcase.strip
      end
      @identified_as_animated
    rescue Cocaine::ExitStatusError => e
      raise Paperclip::Error, "There was an error running `identify` for #{@basename}" if @whiny
    rescue Cocaine::CommandNotFoundError => e
      raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `identify` command. Please install ImageMagick.")
    end
  end
end
