class App < Sinatra::Application
  get "/" do
    haml :index, locals: {} 
  end
end
