class App < Sinatra::Application
  get "/error/list" do
    redirect "/error/list/1"
  end

  get "/error/list/:page" do
    page = params[:page].to_i
    props={}
    props["MessageID"] = {value: lambda{|x| x.message_id}, link: lambda{|x| "/error/#{x.id}"}}
    props["Error"] = {value: lambda{|x| x.error}, link: lambda{|x| "/error/#{x.id}"}}
    props["Date"] = {value: lambda{|x| x.date}}
    props["Source"] = {value: lambda{|x| x.source}}
    props["Env"] = {value: lambda{|x| x.env}}
    data = Error.order(:date).paginate(page, 25)
    haml :list, locals: {header: props, data: data, nxt: page + 1, prev: page -1}
  end

  get "/error/:id" do
    haml :obj, locals: {model: Error[params[:id].to_i], type: "Error"}
  end

end
