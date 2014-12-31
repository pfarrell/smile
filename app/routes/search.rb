class App < Sinatra::Application
  get "/search" do
    redirect "/search/#{params[:q]}" unless params[:q].nil?
    haml :search, locals: {data: {}}
  end

  get "/search/:id" do
    redirect "/search/#{params[:id]}/1"
  end

  get "/search/:id/:page" do
    results = {}
    page = params[:page].to_i
    results[:entries] = Message.search(params[:id], page)
    results[:errors] = Error.search(params[:id], page)
    haml :search, locals: {data: results, nxt: page + 1, prev: page - 1}
  end

end
