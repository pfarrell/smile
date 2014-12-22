Sequel.migration do
  change do
    create_table(:entries) do
      primary_key :id
      String :source
      String :env
      String :message_id
      String :type
      Float  :execution_time
      DateTime :date
      String :succeeded
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
