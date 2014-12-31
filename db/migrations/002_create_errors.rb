Sequel.migration do
  change do
    create_table(:errors) do
      primary_key :id
      String :source
      String :env
      String :type
      String :transaction_id
      String :message_id
      String :loan_id
      DateTime :date
      String :error
      DateTime :created_at
      DateTime :updated_at
      index :date
      index :message_id
    end
  end
end
