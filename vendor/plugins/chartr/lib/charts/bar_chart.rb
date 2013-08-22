class Chartr::BarChart < Chartr::Chart
  attr_accessor :data

  def initialize(params = {})
    @options = { :bars => { :show => true } }
    super
  end


  # Takes data in the form [["foo", 1], ["bar", 2], ["bee", 3],
  # ["bop", 4]] for the xaxis, or [1, "foo"], etc... for 'horizontal'
  # graphs (labels along the y axis).
  def labeled_data(newdata)
    ticks = []
    @data = []
    i = 1

    @options[:bars] ||= {}
    if newdata[0][0].is_a? Numeric
      axis = :yaxis
      @options[:bars][:horizontal] = true
    else
      axis = :xaxis
      @options[:bars][:horizontal] = false
    end

    if @options[:bars] && @options[:bars][:barWidth]
      xlen = @options[:bars][:barWidth]/2
    else
      xlen = 0.5
    end

    newdata.each do |a|

      if axis == :xaxis
        @data << [i,a[1]]
        ticks << [i + xlen, a[0]]
      else
        @data << [a[0],i]
        ticks << [i + xlen, a[1]]
      end
      i += 1
    end
    @data = [@data]
    @options[axis] ||= {}
    @options[axis][:ticks] = ticks
  end

end
