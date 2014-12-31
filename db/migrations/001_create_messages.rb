Sequel.migration do
  change do
    create_table(:messages) do
      primary_key :id
      String :source
      String :env
      String :transaction_id
      String :message_id
      String :loan_id
      String :type
      DateTime :date
      DateTime :created_at
      DateTime :updated_at
      index :date
      index [:env, Sequel.function(:date_trunc, 'hour', :date)]
      index [:env, Sequel.function(:date_trunc, 'day', :date)]
    end
  end
end
