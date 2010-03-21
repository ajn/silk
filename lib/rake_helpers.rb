def install_step(initial_text, error_text = nil, &block)
  begin 
    puts "#{initial_text}..."
    yield
    puts "DONE"
  rescue
    puts error_text || "ERROR! #{$!}"
  ensure
    puts "\n"
  end
end

def ask(message, default_response = "")
  print "#{message} #{default_response ? '[' + default_response + ']' : ''} "
  response = STDIN.gets.chomp
  response.blank? ? default_response : response
end

def confirm(message)
  ask(message, default_response = "n") =~ /y|yes/i
end

def fresh_install?
  !(Silk::Page.table_exists? && Silk::User.table_exists?)
end