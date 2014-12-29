class App < Sinatra::Application
  get "/error/list" do
    redirect "/error/list/1"
  end

  get "/error/list/:page" do
    page = params[:page].to_i
    props={}
    props["MessageID"] = lambda{|x| x.message_id}
    props["Error"] = lambda{|x| x.error}
    props["Date"] = lambda{|x| x.date}
    props["Source"] = lambda{|x| x.source}
    props["Env"] = lambda{|x| x.env}
    data = Error.order(:date).paginate(page, 25)
    haml :list, locals: {header: props, data: data, nxt: page + 1, prev: page -1}
  end

end
