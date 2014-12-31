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
    props["MessageID"] = {value: lambda{|x| x.message_id}, link: lambda{|x| "/message/#{x.id}"}}
    props["Type"] = {value: lambda{|x| x.type}}
    props["Date"] = {value: lambda{|x| x.date}}
    props["Source"] = {value: lambda{|x| x.source}}
    props["Env"] = {value: lambda{|x| x.env}}
    data = Message.order(:id).paginate(page, 25)
    haml :list, locals: {header: props, data: data, nxt: page + 1, prev: page -1}
  end

  get "/message/:id" do
    haml :obj, locals: {model: Message[params[:id].to_i], type: "Message"}
  end

  get "/entries" do
    entries = Message.by_hour
    respond_to do | wants|
      wants.html { haml :report, locals: {data: entries}} 
      wants.json { entries.all.to_json }
    end
  end
end
