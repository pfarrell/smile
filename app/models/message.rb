class Message < Sequel::Model

  def self.by(div)
    f=[]
    d={}
    raw=DB[:messages].group_and_count(:env, Sequel.function(:date_trunc, div, :date)).all
    raw.sort_by{|x| x[:date_trunc]}.each do |msg|
      d[msg[:env]] ||= Hash.new
      d[msg[:env]][msg[:date_trunc]] = msg[:count]
    end
    d.each {|k,v| f << {name: k, data: v}} 
    f
  end

  def self.search(search)
    where(Sequel.or(:message_id => search, :loan_id => search, :transaction_id => search))
  end

end
