module ImageDatasetsHelper  
  def link_to_new_qc(im_ds)
    @var = current_user
    # assumming if user has edit on one protocol, can have button , exclude the -1 scan_procedures 
    # apply limit protocol  on create , edit in create form  
    edit_count =@var.edit_low_scan_procedure_array.length 
    edit_count = edit_count -1
    if edit_count > 0 
    link_to "New Check", new_image_dataset_image_dataset_quality_check_path(im_ds)
    end
  end
  
  def link_to_edit_qc(qc)
    link_to qc.assessment, edit_image_dataset_quality_check_path(qc)
  end
  
  def qc_popup_or_link_to_new(im_ds)
    if im_ds.image_dataset_quality_checks.empty?
      link_to_new_qc(im_ds)
    else 
      link_text = im_ds.image_dataset_quality_checks.last.failing_checks.empty? ? 'Good' :  im_ds.image_dataset_quality_checks.last.failing_checks_list
      link_to(link_text, im_ds.image_dataset_quality_checks.last)
    end
  end
  
  def add_phys_link(form, name)
    link_to_function name do |page|
       page.insert_html :bottom, :phys_files_list, :partial => 'physiology_text_file_fields', :object => form.fields_for(PhysiologyTextFile.new)
    end
  end
  
  def directory_list(path)
    output = ''
    list = `ls #{path}`
    list = list.split

    if list.blank?
      output = "<span class='warning'>Warning: No files in this directory on vtrak!</span>"
    else
      output = list.first(10).join(" ")
      output << '<br>...<br>'
      output << list.last(10).join(" ")
    end
    
    return output.html_safe
  end

end
