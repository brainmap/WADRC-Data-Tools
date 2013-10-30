class Directory < ActiveRecord::Base
	has_many :measurements
	acts_as_list
	

  def chart(options={})
    
    defaults = { :within => nil, :num_x_axis_labels => 15 }
    options = defaults.merge(options)
    
    end_date = DateTime.now
    begin_date = end_date - options[:within]
    xinterval = (end_date.to_i - begin_date.to_i) / options[:num_x_axis_labels]
    xdates = (0...options[:num_x_axis_labels]).to_a.map { |i| end_date - (i*xinterval).seconds }
    xepochs = xdates.map { |d| d.to_i }
    xlabels = xdates.map { |d| d.strftime('%m/%d') }
    
    epochs = measurements.reject {|m| m.size.blank? }.map { |m| m.created_at.to_i }
    sizes = measurements.reject {|m| m.size.blank? }.map { |m|
      (m.size > 2**20) ? m.gb_size : m.mb_size
    }
    
    linechart = Chartr::LineChart.new({
      :xaxis => { :ticks => xepochs.zip(xlabels), :min => xepochs.last, :max => xepochs.first },
      :grid => { :color => '#330', :tickColor => '#360' },
      :points => { :show => true, :fill => true, :radius => 2, :fillColor => '#fff'},
      :lines => { :show => true }
    })
    linechart.data = [epochs.zip(sizes)]
    return linechart
  end
  
  # Returns a measurement of the size of data change from the date provided.
  def change_since(date, options={})
    defaults = { :report_in => :percentage }
    options = defaults.merge(options)
    
    measurements_in_span = measurements.where("created_at >= ?", date)
    return 0 if measurements_in_span.blank?
    m0 = measurements_in_span.first.mb_size
    m1 = measurements_in_span.last.mb_size
    
    if (options[:report_in] == :megabytes)
      return m1 - m0
    else
      return 100.0 * (m1 - m0) / m0
    end
  end
	
	
end