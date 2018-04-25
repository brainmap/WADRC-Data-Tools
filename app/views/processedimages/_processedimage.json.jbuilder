json.extract! processedimage, :id, :file_name, :file_path, :comment, :created_at, :updated_at
json.url processedimage_url(processedimage, format: :json)
