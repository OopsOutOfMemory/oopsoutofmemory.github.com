require "rubygems"
require 'rake'
require 'yaml'
require 'time'
require 'hz2py'

SOURCE = "."
CONFIG = {
  'layouts' => File.join(SOURCE, "_layouts"),
  'post' => File.join(SOURCE, "_posts"),
  'page' => File.join(SOURCE, "page"),
  'life' => File.join(SOURCE, "life"),
  'post_ext' => "md",
}

def ask(message, valid_options)
  if valid_options
    answer = get_stdin("#{message} #{valid_options.to_s.gsub(/"/, '').gsub(/, /,'/')} ") while !valid_options.include?(answer)
  else
    answer = get_stdin(message)
  end
  answer
end

def get_stdin(message)
  print message
  STDIN.gets.chomp
end

# Usage: rake post title="Post Name"
desc "Begin a new post in #{CONFIG['posts']}"
task :post do
  abort("rake aborted: '#{CONFIG['posts']}' directory not found.") unless FileTest.directory?(CONFIG['posts'])
  title = ENV["title"] || "new－post"

  category = ENV["category"] || "default"
  description = ENV["description"] || ""
  tags = ENV["tags"] || "[]"
  slug = Hz2py.do(title, :join_with => '-', :to_simplified => true)
  slug = slug.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  begin
    date = (ENV['date'] ? Time.parse(ENV['date']) : Time.now).strftime('%Y-%m-%d')
  rescue Exception => e
    puts "Error - date format must be YYYY-MM-DD, please check you typed it correctly!"
    exit -1
  end

  filename = File.join(CONFIG['posts'], category)
  if !File.directory?(filename)
    mkdir_p filename
  end
  filename = File.join(filename, "#{date}-#{slug}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  # User confirm 
  abort("rake aborted!") if ask("The post #{filename} will be created in category #{category}, are you sure?", ['y', 'n']) == 'n'

  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title}\""
    post.puts "description: \"#{description}\""
    post.puts "category: \"#{category}\""
    post.puts "tags: \"#{tags}\""
    post.puts "---"
    post.puts "Included file 'JB/setup' not found in _includes directory"
  end
end # task :post

# Usage: rake life title="Post Name"
desc "Begin a new life-post in #{CONFIG['life']}"
task :life do
  abort("rake aborted: '#{CONFIG['life']}' directory not found.") unless FileTest.directory?(CONFIG['life'])
  title = ENV["title"] || "New-Life"
  filename = File.join(CONFIG['life'], "#{title.gsub(/ /,'-').gsub(/[^\w-]/, '')}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  puts "Creating new life-post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: life"
    post.puts "title: #{title.gsub(/-/,' ')}"
    post.puts "---"
  end
end

# Usage: rake page title="Page Name"
desc "Begin a new page in #{CONFIG['page']}"
task :page do
  abort("rake aborted: '#{CONFIG['page']}' directory not found.") unless FileTest.directory?(CONFIG['page'])
  title = ENV["title"] || "New-Page"
  filename = File.join(CONFIG['page'], "#{title.gsub(/ /,'-').gsub(/[^\w-]/, '')}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end
  puts "Creating new page: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: blog"
    post.puts "title: #{title.gsub(/-/,' ')}"
    post.puts "---"
  end
end
