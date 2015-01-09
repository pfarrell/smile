require '../app'
require 'json'
require 'byebug'

def analytic?(str)
  str =~ / - Type/
end

def info?(str)
  str =~ / - MessageDQ/
end

def remote_error?(str)
  str =~ /Handler returned errorStatus for:/
end

def local_error?(str)
  str =~ / - Exception generated for: /
end

def parse_analytic(str)
  pattern = /(?<date>[\d :,-]+) .* INFO .* - Type:\[(?<type>\S*)\],MessageId:\[(?<message_id>\S*)\],ExecutionTimeMillis\[(?<execution_time>[\d.]*)\],Succeeded:\[(?<succeeded>.*)\]/
  str.match(pattern)
end

def parse_log(str, type)
  pattern = /(?<date>[\d :,-]*) \[(?<route>[\w\.-]*)\-listener\].*#{type}.*: \[(?<json>.*)\]/
  str.match(pattern)                        
end

def parse_info(str)
  parse_log(str, "INFO")
end

def parse_error(str)
  parse_log(str, "ERROR")
end

def parse_json(json, source, env, date)
  return if json == ''
  json = json.gsub('\\"', '"')
  json = json.gsub('"{', '{')
  json = json.gsub('}"', '}')
  obj = JSON.parse(json)
  #byebug if obj["RabbitAccountBasedMessage"] != nil
  obj = obj["RabbitAccountBasedMessage"] unless obj["RabbitAccountBasedMessage"].nil?
  obj["env"] = env
  obj["source"] = source
  obj["date"] = date.gsub!(/ /, 'T')
  obj
end

def handle_analytic(line, source, env)
  parts = parse_analytic(line)
  date = parts['date'].gsub(/,/, '.')
  timing = Timing.find(source: ARGV[1], date: date, message_id: parts['message_id'])
  return unless timing.nil?
  timing = Timing.new
  timing.type = parts['type']
  timing.message_id = parts['message_id']
  timing.date = date
  timing.execution_time = parts['execution_time']
  timing.succeeded = parts['succeeded']
  timing.source = ARGV[1]
  timing.env = ARGV[2]
  timing.save
  make_analytic_hash(date, parts, source, env)
end

def make_analytic_hash(date, parts, source, env)
  ret = {}
  ret["source"] = source
  ret["env"] = env
  ret["date"] = date.gsub!(/ /, 'T')
  ret['execution_time'] = parts["execution_time"].to_i
  ret['message_id'] = parts["message_id"]
  ret['succeeded'] = parts['succeeded']
  ret['type'] = parts['type']
  ret
end

def handle_error(error, trace=[])
  parts = parse_error(error)
  date = parts['date'].gsub(/,/, '.')
  j = parse_json(parts['json'], ARGV[1], ARGV[2], date)
  return if j.nil?
  error = Error.find(source: ARGV[1], date: date, message_id: j["id"].to_s)
  return unless error.nil?        
  error = Error.new
 
  error.date = date
  error.source = ARGV[1]
  error.env = ARGV[2]
  error.type = j["messageType"]
  error.message_id = j['id'].to_s
  loan_id = j['entityNumber'] || j['LoanID'] || j['accountID']
  error.loan_id = loan_id.to_s
  error.error = trace[0]
  error.save
  j["docid"] = error.id
  j
end

def handle_info(info)
  parts = parse_info(info)
  date = parts['date'].gsub(/,/, '.')
  j = parse_json(parts['json'], ARGV[1], ARGV[2], date)
  msg = Message.find(source: ARGV[1], date: date, message_id: j["id"].to_s)
  if(!msg.nil?) 
    loan_id = j['entityNumber'] || j['LoanID'] || j['accountID']
    msg.loan_id = loan_id
    msg.save
  end
  return unless msg.nil?
  msg = Message.new
  msg.date = date
  msg.type = j["messageType"]
  msg.source = ARGV[1]
  msg.env = ARGV[2]
  msg.message_id = j['id'].to_s
  loan_id = j['entityNumber'] || j['LoanID'] || j['accountID']
  msg.loan_id = loan_id.to_s
  msg.save
  j["docid"] = msg.id
  j
end

def error_start?(line)
  line =~ /\] ERROR/ 
end

def error_continuation?(line)
  line =~ /^[A-Za-z \t]/
end

def error_completion?(line)
  line =~ /^20/
end

error_collect, error, trace = nil
es = ElasticSearch.new

ctr=0
puts "processing #{ARGV[0]}"
File.foreach(ARGV[0]).each do |line|
  ctr+=1
  print '.' if ctr %1000 == 0
  if(local_error?(line))
    error = line
    error_collect = true
    trace = []
  elsif(error_collect && error_continuation?(line))
    trace << line
  elsif(error_collect && error_completion?(line))
    json = handle_error(error, trace)
    es.save("s2p", "error", json["docid"], json.to_json) unless json.nil?
    error_collect = false
    json = handle_analytic(line, ARGV[1], ARGV[2]) if analytic?(line)
    es.save("s2p", "analytic", json["message_id"], json.to_json) unless json.nil? 
    json = handle_info(line) if info?(line)
  elsif(info?(line)) 
    json = handle_info(line)
    es.save("s2p", "info", json["docid"], json.to_json) unless json.nil?
  elsif(analytic?(line))
    json = handle_analytic(line, ARGV[1], ARGV[2])
    es.save("s2p", "analytic", json["message_id"], json.to_json) unless json.nil? 
  elsif(remote_error?(line))
    json = handle_error(line)
    es.save("s2p", "error", json["docid"], json.to_json) unless json.nil?
  end
end
