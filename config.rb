require 'active_support/all'

# CONFIG

set :markdown_engine, :redcarpet

set :css_dir,    'assets/stylesheets'
set :js_dir,     'assets/javascripts'
set :images_dir, 'assets/images'

activate :autoprefixer
activate :directory_indexes
activate :livereload

activate :contentful do |f|
  f.access_token  = ENV['CONTENTFUL_ACCESS_TOKEN']
  f.space         = { site: ENV['CONTENTFUL_SPACE'] }
  f.content_types = {
    page:      ENV['CONTENTFUL_PAGE_KEY'],
    blog_post: ENV['CONTENTFUL_BLOG_POST_KEY']
  }
end

activate :deploy do |deploy|
  deploy.method   = :git
  deploy.strategy = :force_push
end

configure :build do
  activate :asset_hash
  activate :minify_css
  activate :minify_javascript
  activate :relative_assets
end

# PAGES

helpers do
  def menu_link(title, link)
    unless page_classes[/(\S+\s+){#{1}}/].blank?
      klass = (link == page_classes[/(\S+\s+){#{1}}/].strip ? 'active' : nil)
    end
    link_to title, "/#{link}", class: klass
  end
end

page '/sitemap.xml', layout: false

data.site.page.each do |page|
  page "/#{page[1][:slug].downcase}.html", proxy: '/pages/show.html', ignore: true do
    @page     = page[1]
    @title    = page[1][:title]
    @slug     = page[1][:slug]
    @body     = page[1][:body]
    @position = page[1][:position]
  end
end

data.site.blog_post.each do |post|
  page "/blog/#{post[1][:slug]}.html", proxy: '/blog/show.html', ignore: true do
    @post     = post[1]
    @title    = post[1][:title]
    @slug     = post[1][:slug]
    @body     = post[1][:body]
    @image    = post[1][:image]
    @date     = post[1][:date]
    @tags     = post[1][:tags]
  end
end

@recent_posts = data.site.blog_post.sort_by { |post| post[1][:date] }.reverse.first(5)


@archive_months = data.site.blog_post.map { |post| post[1][:date].strftime('%B %Y') }.uniq

@archive_months.each do |date_string|
  date = Date.parse(date_string)

  page "/blog/archive/#{date.strftime("%Y")}/#{date.strftime("%m")}.html", proxy: '/blog/archive.html', ignore: true do
    @date = date.strftime('%B %Y')
    @archive_posts = data.site.blog_post.to_a.select do |post|
      post[1][:date].strftime('%B %Y') == date.strftime('%B %Y')
    end
  end
end


@all_tags = data.site.blog_post.map { |post| post[1][:tags] }.flatten.uniq

@all_tags.each do |tag|
  page "/blog/tags/#{tag}.html", proxy: '/blog/tag.html', ignore: true do
    @tag = tag
    @tag_posts = data.site.blog_post.to_a.select do |post|
      post[1][:tags].include? tag
    end
  end
end

