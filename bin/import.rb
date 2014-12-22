require '../app'

def analytic_line?(str)
  str =~ / - Type/
end

def parse(str)
  pattern = /(?<date>[\d-:,]+) .* INFO .* - Type:\[(?<type>\S*)\],MessageId:\[(?<message_id>\S*)\],ExecutionTimeMillis\[(?<execution_time>[\d.]*)\],Succeeded:\[(?<succeeded>.*)\]/
  str.match(pattern)
end
  

File.foreach(ARGV[0]).each do |line|
  if(analytic_line?(line))
    parts = parse(line)
    date = parts['date'].gsub(/,/,'.')
    entry = Entry.find(source: ARGV[1], date: date, message_id: parts['message_id'])
    next unless entry.nil?
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
end


