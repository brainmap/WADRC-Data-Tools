module HelpsHelper
  
  def help_tag_links(help)
    return "" unless help.tag_list.any?
    tag_links = help.tag_list.collect do |tag|
      link_to tag, :controller => 'helps', :action => 'tag', :id => tag
    end
    tag_string = tag_links.join(', ')
    "" + tag_string + ""
  end
  
end
