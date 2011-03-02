# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def key_val_table(id, options)
    return nil if options.nil?
    table = "<table class=\"key_value\" id=\"#{id}\">"
    options.each_pair do |k,v|
      kstring = stringify_symbol(k).capitalize
      vstring = v.blank? ? "" : v.to_s
      table += "<tr><th>#{kstring}:</th><td>#{vstring}</td></tr>" unless v.blank?
    end
    table += '</table>'
    return table.html_safe
  end

  def popup_note(prompt, content, options={})
    return nil if content.nil?
    styles = ""
    if options[:align] == 'right'
      styles = "right:None, left:-10px"
    elsif options[:align] == 'left'
      styles = "right:-10px, right:None"
    end
    popup = "<div class=\"sticky_hole\">"
    popup += "<a class=\"sticky_spawner\">#{prompt.to_s}</a>"
    popup += "<div class=\"hidden_sticky\" style=\"#{styles}\">#{content}</div>"
    popup += "</div>"
    return popup.html_safe
  end

  def footer(width)
    ("<td>&nbsp;</td>" * width).html_safe
  end

  def clearing_br
    '<br style="clear:both" >'.html_safe
  end

  def gender(field)
    if field == 1
      return "M"
    elsif field == 2
      return "F"
    else
      return "unknown"
    end
  end

  def wrap_enrollment(field)
    field == -1 ? "wrap" : "nowrap"
  end

  def genetic_status(a1, a2)
    if a1 == 4 or a2 == 4
      "&epsilon;4 +".html_safe
    elsif a1 == nil or a1 == 0 or a2 == nil or a2 == 0
      ""
    else
      "&epsilon;4 –".html_safe
    end
  end

  # def pagination_info(collection, options = {})
  #   entry_name = options[:entry_name] ||
  #     (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
  # 
  #   if collection.total_pages < 2
  #     case collection.size
  #     when 0; "No #{entry_name.pluralize} found"
  #     when 1; "<b>1</b> #{entry_name.capitalize}"
  #     else;   "<b>#{collection.size}</b> #{entry_name.capitalize.pluralize}"
  #     end
  #   else
  #     %{#{entry_name.capitalize.pluralize} <b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
  #       collection.offset + 1,
  #       collection.offset + collection.length,
  #       collection.total_entries
  #     ]
  #   end
  # end

  def stringify_symbol(symbol)
    symbol.to_s.gsub('_',' ')
  end

  def slide_toggler(element_id, label = image_tag('comment_bubble.gif'), alt_label = label)
    link_to_function(label, nil, :id => "#{element_id}_toggler", 
        :onclick => "this.innerHTML = this.innerHTML == '#{label}' ? '#{alt_label}' : '#{label}';") do |page|
          page.visual_effect :toggle_blind, element_id, :duration => 0.3
        end
  end

  def spawn(element_id, content)
    return nil if content.empty?
    link_to_function(image_tag("comment_bubble.gif"), nil, :id => 'spawner_icon') do |page|
      page[element_id].replace_html(content)
      page.visual_effect :toggle_blind, element_id, :duration => 0.3
    end
  end


end
