node['jenkins2']['folders'].each do |fldr, opts|
  jenkins2_folder fldr do
    path opts['path']
  end
end
