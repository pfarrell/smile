class App < Sinatra::Application
  get "/messages" do
    haml :messages
  end

  get "/entries" do
    entries = Entry.by_hour
    respond_to do | wants|
      wants.html { haml :report, locals: {data: entries}} 
      wants.json { entries.all.to_json }
    end
  end
end
