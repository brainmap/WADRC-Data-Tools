module ImageDatasetsHelper  
  def link_to_new_qc(im_ds)
    link_to "perform", new_image_dataset_image_dataset_quality_check_path(im_ds)
  end
  
  def link_to_edit_qc(qc)
    link_to qc.assessment, edit_image_dataset_quality_check_path(qc)
  end
  
  def qc_popup_or_link_to_new(im_ds)
    im_ds.image_dataset_quality_checks.empty? ? link_to_new_qc(im_ds) : link_to('view most recent', im_ds.image_dataset_quality_checks.last)
  end
end
