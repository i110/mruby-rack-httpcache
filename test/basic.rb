assert("Rack::HTTPCache") do
  counter = 0
  app = proc {
    counter += 1
    [200, {}, [counter.to_s]]
  }

  etag = proc {
    counter += 1
    [200, {'ETag' => '"foobar"'}, [counter.to_s]]
  }

  Dir.mktmpdir {|dir|
    storage = Rack::HTTPCache::Disk.new(dir)
    storage = Rack::HTTPCache::Disk.new(dir)
    cache = Rack::HTTPCache.new(app, storage)

    res = Rack::MockRequest.new(cache).get("/")
    assert_true res.ok?, 'ok1'
    assert_equal res.body, '1'

    res = Rack::MockRequest.new(cache).get("/")
    assert_true res.ok?, 'ok2'
    puts '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
    puts res.body
    assert_equal res.body, '1'

    req = Rack::MockRequest.new(etag)
    res = req.get("/", "HTTP_IF_NONE_MATCH" => '"foobar"')
    assert_equal res.status, 304
    res = req.get("/", "HTTP_IF_NONE_MATCH" => '"otherwise"')
    assert_equal res.status, 200
  }
end
