class App < Sinatra::Application
  get "/errors" do
    haml :errors
  end
end
