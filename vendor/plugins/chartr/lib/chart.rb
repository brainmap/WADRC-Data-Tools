class Hash

  # Merges self with another hash, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  #
  # Thanks to whoever made it.

  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end
    target
  end
end

class Chartr::Chart
  attr_accessor :data

  # Initialize the chart with the options listed here:
  # http://solutoire.com/flotr/docs/options/
  def initialize(params = {})
    @options ||= {}
    @options = @options.deep_merge(params)
    @data = []
  end

  def output(canvasname)
    return "Flotr.draw($('#{canvasname}'), #{@data.to_json}, #{@options.to_json});"
  end
end
