class App < Sinatra::Application
  get "/search" do
    redirect "/search/#{params[:q]}" unless params[:q].nil?
    haml :search, locals: {data: {}}
  end

  get "/search/:id" do
    results = {}
    results[:entries] = Entry.search(params[:id])
    results[:errors] = Error.search(params[:id])
    haml :search, locals: {data: results}
  end

end
