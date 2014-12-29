class App < Sinatra::Application
  get "/message/graphs" do
    haml :message_graph
  end

  get "/message/list" do
    redirect "/message/list/1"
  end

  get "/message/list/:page" do
    page = params[:page].to_i
    props={}
    props["MessageID"] = lambda{|x| x.message_id}
    props["Type"] = lambda{|x| x.type}
    props["ExecutionTime"] = lambda{|x| x.execution_time}
    props["Succeeded"] = lambda{|x| x.succeeded}
    props["Date"] = lambda{|x| x.date}
    props["Source"] = lambda{|x| x.source}
    props["Env"] = lambda{|x| x.env}
    data = Entry.order(:id).paginate(page, 25)
    haml :list, locals: {header: props, data: data, nxt: page + 1, prev: page -1}
  end

  get "/entries" do
    entries = Entry.by_hour
    respond_to do | wants|
      wants.html { haml :report, locals: {data: entries}} 
      wants.json { entries.all.to_json }
    end
  end
end
