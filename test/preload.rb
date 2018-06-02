require 'test/assert.rb'
class Dir
  def self._rm_r(dir)
    Dir.entries(dir).sort.each {|entry|
      unless entry == '.' || entry == '..'
        path = File.join(dir, entry)
        if Dir.exist?(path)
          _rm_r(path)
        elsif File.exist?(path)
          File.unlink(path)
        end
      end
    }
    Dir.unlink(dir)
  end
  def self.mktmpdir(&block)
    dir = '.'
    while Dir.exist?(dir) do
      dir = File.join(Dir.tmpdir, (rand(1 << 24).to_s))
    end
    begin
      Dir.mkdir(dir)
      block.call(dir)
    ensure
      _rm_r(dir) if Dir.exist?(dir)
    end
  end
end
