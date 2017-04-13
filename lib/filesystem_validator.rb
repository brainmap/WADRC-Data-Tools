class FilesystemValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    unless valid_path?
      object.errors[attribute] << (options[:message] || "must exist and not be a symlink") 
    end
  end

  def valid_path?
    File.exists?(path) and not symlink_in_path?
  end
  
  def symlink_in_path?
    Pathname.new(path).ascend do |trunk|
      return true if File.symlink? trunk 
    end
    return false
  end
end
