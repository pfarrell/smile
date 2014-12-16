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
    entry = Entry.find_or_create(source: ARGV[1], date: date, message_id: parts['message_id'])
    entry.type = parts['type']
    entry.date = date
    puts entry.date
    entry.execution_time = parts['execution_time']
    entry.succeeded = parts['succeeded']
    entry.source = ARGV[1]
    entry.save
  end
end


