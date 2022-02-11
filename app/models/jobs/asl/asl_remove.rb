def remove_tracker(tracker_id)
  tracker = Trtype.find(tracker_id)
  tracker.trfiles.each do |trfile|
    trfile.trfileimages.each do |img|
      if ['html', 'cg_tcCBF', 'json'].include?(img.image_category.to_s)
        processed_pdf = Processedimage.find(img.image_id)
        processed_pdf.delete
      end
      img.delete
    end
    trfile.tredits.each do |tredit|
      tredit.tredit_actions.each do |action|
        action.delete
      end
      tredit.delete
    end
    trfile.delete
  end
end
