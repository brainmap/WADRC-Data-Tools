module VisitsHelper
  def show_bool(field)
    html = case field
    when "yes" then
      "<td style='background-color: #bbffbb; min-width: 1.5em; max-width: 3em;'>yes</td>"
    when "no" then 
      "<td style='background-color: #cccccc; min-width: 1.5em; max-width: 3em;'>no</td>"
    when "n/a" then
      "<td style='background-color: #ffbbbb; min-width: 1.5em; max-width: 3em;'>n/a</td>"
    else 
      "<td>#{field}</td>"
    end
    return html.html_safe
  end
  
  def show_bool_cell_color(field)
    html = case field
    when "yes" then
      " style='background-color: #bbffbb; ' "
    when "no"  then
      " style='background-color: #cccccc;' "
    when "n/a" then 
      "  style='background-color: #ffbbbb;' "
    else 
      " "
    end
    return html.html_safe
  end

end

def show_rad_review(field)
  html = case field
  when "n/a" then
    "<td style='background-color: #ffbbbb; min-width: 1.5em; max-width: 3em;'>n/a</td>"
  when "no" then
    "<td style='background-color: #cccccc; min-width: 1.5em; max-width: 3em;'>no</td>"
  when "yes" then
    "<td style='background-color: #bbffbb; min-width: 1.5em; max-width: 3em;'>yes</td>"
  else
    "<td style='background-color: #eee; min-width: 1.5em; max-width: 3em;'>#{field}</td>"
  end
  return html.html_safe
end

def show_which_dicom(field)
  html = case field
  when :blank? then
    "<td style='background-color: #eee; min-width: 1.5em; max-width: 1.5em;'>n/a</td>"
  else
    "<td style='background-color: #eee; min-width: 1.5em; max-width: 1.5em;'>#{field}</td>"
  end
  return html.html_safe
end

# This produces a small form to POST the RMR number of a visit to the radiology
# revie site for looking up Scan Numbers.
# This creates a form (the only way I know of POSTing) so it cannot be embedded
# in other forms.
def lookup_radiology_button(rmr)
  form_tag("https://www.radiology.wisc.edu/protected/neuroResearchScans/scanList.php")
  hidden_field_tag("origin", "searchForm")
  hidden_field_tag("subjID",@visit.rmr)
  submit_tag("Check Radiology Site")
end



