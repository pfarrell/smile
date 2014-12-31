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
  puts str
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

def parse_json(json)
  return if json == ''
  obj = JSON.parse(json)
  #byebug if obj["RabbitAccountBasedMessage"] != nil
  obj = obj["RabbitAccountBasedMessage"] unless obj["RabbitAccountBasedMessage"].nil?
  obj
end

def handle_analytic(line)
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
end

def handle_error(error, trace=[])
  parts = parse_error(error)
  j = parse_json(parts['json'])
  return if j.nil?
  date = parts['date'].gsub(/,/, '.')
  error = Error.find(source: ARGV[1], date: date, message_id: j["id"].to_s)
  return unless error.nil?        
  error = Error.new
 
  error.date = date
  error.source = ARGV[1]
  error.env = ARGV[2]
  error.type = j["messageType"]
  error.message_id = j['id'].to_s
  loan_id = j['entityNumber'] || j['LoanID']
  error.loan_id = loan_id.to_s
  error.error = trace[0]
  error.save
end

def handle_info(info)
  parts = parse_info(info)
  j = parse_json(parts['json'])
  date = parts['date'].gsub(/,/, '.')
  msg = Message.find(source: ARGV[1], date: date, message_id: j["id"].to_s)
  return unless msg.nil?
  msg = Message.new
  msg.date = date
  msg.type = j["messageType"]
  msg.source = ARGV[1]
  msg.env = ARGV[2]
  msg.message_id = j['id'].to_s
  loan_id = j['entityNumber'] || j['LoanID']
  msg.loan_id = loan_id.to_s
  msg.save
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

File.foreach(ARGV[0]).each do |line|
  if(local_error?(line))
    error = line
    error_collect = true
    trace = []
  elsif(error_collect && error_continuation?(line))
    trace << line
  elsif(error_collect && error_completion?(line))
    handle_error(error, trace)
    error_collect = false
    handle_analytic(line) if analytic?(line)
    handle_info(line) if info?(line)
  elsif(info?(line)) 
    handle_info(line)
  elsif(analytic?(line))
    handle_analytic(line)
  elsif(remote_error?(line))
    handle_error(line)
  end
end
