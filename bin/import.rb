require '../app'
require 'json'
require 'byebug'

def analytic_line?(str)
  str =~ / - Type/
end

def parse_analytic(str)
  pattern = /(?<date>[\d-:,]+) .* INFO .* - Type:\[(?<type>\S*)\],MessageId:\[(?<message_id>\S*)\],ExecutionTimeMillis\[(?<execution_time>[\d.]*)\],Succeeded:\[(?<succeeded>.*)\]/
  str.match(pattern)
end

def parse_error(str)
  pattern = /(?<date>[\d :,\-]*) \[(?<route>[\w\.-]*)\-listener\].*ERROR.*: \[(?<json>.*)\]/
  str.match(pattern)
end

def parse_json(json)
  return if json == ''
  obj = JSON.parse(json)
end

def handle_analytic(line)
  parts = parse_analytic(line)
  date = parts['date'].gsub(/,/,'.')
  entry = Entry.find(source: ARGV[1], date: date, message_id: parts['message_id'])
  return unless entry.nil?
  entry = Entry.new
  entry.type = parts['type']
  entry.message_id = parts['message_id']
  entry.date = date
  entry.execution_time = parts['execution_time']
  entry.succeeded = parts['succeeded']
  entry.source = ARGV[1]
  entry.env = ARGV[2]
  entry.save
end

def handle_error(error, trace)
  parts = parse_error(error)
  msg = parse_json(parts['json'])
  return if msg.nil?
  date = parts['date'].gsub(/,/,'.')
  error = Error.find(source: ARGV[1], date: date, message_id: msg["id"].to_s)
  return unless error.nil?        
  error = Error.new
 
  error.date = date
  error.source = ARGV[1]
  error.env = ARGV[2]
  error.message_id = msg['id'].to_s
  error.error = trace[0]
  error.save
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
  if(!error_collect && analytic_line?(line))
    handle_analytic(line)
  elsif(error_start?(line))
    error = line
    error_collect = true
    trace = []
  elsif(error_collect && error_continuation?(line))
    trace << line
  elsif(error_collect && error_completion?(line))
    handle_error(error, trace)
    error_collect = false
    handle_analytic(line) if analytic_line?(line)
  end
end
