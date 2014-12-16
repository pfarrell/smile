class MyModel
  def hello(str=nil)
    str = "stranger" if str.nil? || str.empty?
    "cioa, #{str}"
  end
end
