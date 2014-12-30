class Error < Sequel::Model

  def self.by(div)
    f=[]
    d={}
    raw=DB[:entries].group_and_count(:env, Sequel.function(:date_trunc, div, :date)).all
    raw.sort_by{|x| x[:date_trunc]}.each do |entry|
      d[entry[:env]] ||= Hash.new
      d[entry[:env]][entry[:date_trunc]] = entry[:count]
    end
    d.each {|k,v| f << {name: k, data: v}} 
    f
  end

  def self.search(search)
    where(Sequel.or(:message_id => search, :loan_id => search, :transaction_id => search))
  end

end
