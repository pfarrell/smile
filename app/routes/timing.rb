class App < Sinatra::Application
  get "/timing/graphs" do
    haml :timing_graph
  end

  get "/timing/list" do
    redirect "/timing/list/1"
  end

  get "/timing/list/:page" do
    page = params[:page].to_i
    props={}
    props["MessageID"] = {value: lambda{|x| x.message_id}, link: lambda{|x| "/message/#{x.id}"}}
    props["Type"] = {value: lambda{|x| x.type}, link: lambda{|x| "/timing/#{x.id}"}}
    props["ExecutionTime"] = {value: lambda{|x| x.execution_time}}
    props["Succeeded"] = {value: lambda{|x| x.succeeded}}
    props["Date"] = {value: lambda{|x| x.date}}
    props["Source"] = {value: lambda{|x| x.source}}
    props["Env"] = {value: lambda{|x| x.env}}
    data = Entry.order(:id).paginate(page, 25)
    haml :list, locals: {header: props, data: data, nxt: page + 1, prev: page -1}
  end

  get "/timing/:id" do
    haml :obj, locals: {model: Entry[params[:id].to_i], type: "Message"}
  end

  get "/timings" do
    entries = Timing.by_hour
    respond_to do | wants|
      wants.html { haml :report, locals: {data: entries}} 
      wants.json { entries.all.to_json }
    end
  end
end
