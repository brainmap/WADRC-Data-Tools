module ParticipantsHelper
  def flag(field)
    field == 0 ? "" : "x"
  end
  
  def allele(field)
    ((field == nil or field == 0) ? "" : "&epsilon;#{field}").html_safe
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
  
  def gender(field)
    field == 1 ? "M" : "F"
  end
  
end

