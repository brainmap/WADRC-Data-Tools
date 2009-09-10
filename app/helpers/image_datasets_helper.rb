module ImageDatasetsHelper  
  def link_to_new_qc(im_ds)
    link_to "perform", new_image_dataset_image_dataset_quality_check_path(im_ds)
  end
  
  def link_to_edit_qc(qc)
    link_to qc.assessment, edit_image_dataset_quality_check_path(qc)
  end
  
  def qc_popup_or_link_to_new(im_ds)
    if im_ds.image_dataset_quality_checks.empty?
      link_to_new_qc(im_ds)
    else 
      link_text = im_ds.image_dataset_quality_checks.last.failing_checks.empty? ? 'good' :  im_ds.image_dataset_quality_checks.last.failing_checks.to_a.join(', ')
      link_to(link_text, im_ds.image_dataset_quality_checks.last)
    end
  end
  
  def add_phys_link(name)
    link_to_function name do |page|
       page.insert_html :bottom, :phys_files_list, :partial => 'physiology_text_file', :object => PhysiologyTextFile.new
    end
  end
  

end
