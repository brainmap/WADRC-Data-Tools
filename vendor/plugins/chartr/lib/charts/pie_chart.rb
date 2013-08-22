class Chartr::PieChart < Chartr::Chart
  def initialize(params = {})
    @options = { :pie => { :show => true } }

    super
  end

  # Piechart data is a bit different.  We can't really have different
  # series, so we just take the data as a simply array.
  def data=(series)
    @data = []
    series.each do |d|
      @data << [[0,d]]
    end
  end
end
