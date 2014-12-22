class App < Sinatra::Application
  get "/" do
    haml :index, locals: {}#data: Entry.env_by_hour} 
  end
end
