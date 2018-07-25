json.extract! networkgroup, :id, :name, :networkgroup_type, :status_flag, :comment, :created_at, :updated_at
json.url networkgroup_url(networkgroup, format: :json)
