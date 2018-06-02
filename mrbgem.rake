MRuby::Gem::Specification.new('mruby-rack-httpcache') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Ichito Nagata'
  spec.summary = 'Rack::HTTPCache'
  spec.version = '0.0.1'
  spec.add_dependency 'mruby-onig-regexp'
  spec.add_dependency 'mruby-io'
  spec.add_dependency 'mruby-rack', :github => 'i110/mruby-rack'
  spec.add_dependency 'mruby-json', :github => 'mattn/mruby-json'
  spec.add_test_dependency 'mruby-require', :github => 'iij/mruby-require'
  spec.add_test_dependency 'mruby-tempfile', :github => 'iij/mruby-tempfile'

  # order matters
  spec.rbfiles = [
    "#{dir}/mrblib/rack/httpcache/stream.rb",
    "#{dir}/mrblib/rack/httpcache/storage.rb",
    "#{dir}/mrblib/rack/httpcache/cache_control.rb",
    "#{dir}/mrblib/rack/httpcache/utils.rb",
    "#{dir}/mrblib/rack/httpcache/response.rb",
    "#{dir}/mrblib/rack/httpcache/request.rb",
    "#{dir}/mrblib/rack/httpcache.rb",
  ]
  spec.test_rbfiles = [
    "#{dir}/test/basic.rb",
  ]
  spec.test_preload = "#{dir}/test/preload.rb"
end
