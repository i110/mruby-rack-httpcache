module Rack

  class HTTPCache

    class Storage
      def initialize(options={})
        @options = options
      end
      def lookup(req)
        return nil unless reader = reader(req)
        if block_given?
          yield reader
        else
          Response.new(req, reader.status, reader.res_headers, reader)
        end
      end
      def store(res, options = {})
        writer = writer(res)
        writer.flush(res.body) if res.body
        writer.close

        if res.body
          rewind = options.key?(:rewind) ? options[:rewind] : true
          if rewind
            if res.body.respond_to?(:rewind)
              res.body.rewind
            else
              res.body.close if res.body.respond_to?(:close)
              res.body = reader(res.req) # reopen
              unless res.body
                raise "couldn't reopen cache body: #{res.req.url}"
              end
            end
          end
        end

        res
      end
      def purge(req)
        raise NotImplementedError
      end
      def tee(res)
        res.body = TeeStream.new(res.body, writer(res))
        res
      end
      def writer(res)
        raise NotImplementedError
      end
      def reader(req)
        raise NotImplementedError
      end
    end

    class Disk < Storage
      CACHE_VERSION = 1 # TODO variablize

      class DiskReader < Rack::HTTPCache::CacheReader
        def initialize(path)
          file = ::File.open(path, 'r')
          super(file)
          @header = [:meta, :req_headers, :res_headers].map{|k| [k, ::JSON.parse(file.readline)] }.to_h
          @rewind_pos = file.pos
        end
        def path
          io.path
        end
        def rewind
          io.pos = @rewind_pos
          0
        end
      end

      class DiskWriter < Rack::HTTPCache::CacheWriter
        attr_reader :path, :temp_path
        def initialize(path, header, options={})
          @path = path
          @options = options
          prepare_dir(@path)

          # NOTE: we should use atomic operation (i.e. O_EXCL and O_CREAT flags) to create temporary file,
          # but mruby-io currently doesn't have that features, so generate randomized path and do retries
          loop do
            @temp_path = "#{@path}.temp.#{rand((1 << 31) - 1).to_s}"
            break unless ::File.exist?(@temp_path)
          end

          file = ::File.open(@temp_path, 'w', 0600)
          file.sync = true if @options[:sync]
          super(file, header)

          file.puts(::JSON.generate(header[:meta]), ::JSON.generate(header[:req_headers]), ::JSON.generate(header[:res_headers]))
        end

        def close
          super
          if aborted
            begin
              ::File.delete(temp_path) if ::File.exist?(temp_path)
            rescue
            end
          else
            begin
              ::File.rename(temp_path, path) if ::File.exist?(temp_path)
            rescue => e
              begin
                ::File.delete(temp_path) if ::File.exist?(temp_path)
              rescue
              end
              raise e
            end
          end
        end

        def prepare_dir(file_path)
          dir = ::File.dirname(file_path)
          stack = []
          until Dir.exist?(dir)
            stack.push(dir)
            dir = ::File.dirname(dir)
          end
          stack.reverse_each do |path|
            begin
              Dir.mkdir path, 0700
            rescue SystemCallError => e
              raise e unless Dir.exist?(path)
            end
          end
          stack[0]
        end

      end

      def initialize(dir, options={})
        super(options)
        @dir = dir
      end

      def reader(req)
        key = req.cache_key
        file_path = file_path(key)
        if !::File.exist?(file_path)
          return nil
        end
        
        reader = DiskReader.new(file_path)

        # TODO vary header?
        unless reader.key == key && reader.version == CACHE_VERSION
          reader.close
          return nil
        end

        reader
      end

      def writer(res)
        key = res.req.cache_key
        file_path = file_path(key)
        meta = {
          "version"     => CACHE_VERSION,
          "key"         => key,
          "status"      => res.status,
          "reqtime"     => res.req.time.to_f,
          "restime"     => res.time.to_f,
          # "valid_until" => valid_until,
        }
        req_headers = res.req.headers.to_h
        res_headers = res.headers.to_h

        return DiskWriter.new(
            file_path,
            { :meta => meta, :req_headers => req_headers, :res_headers => res_headers },
            { :sync => @options[:sync] },
        )
      end

      def purge(req)
        key = req.cache_key
        file_path = file_path(key)
        return false unless ::File.exist?(file_path)
        ::File.delete(file_path) > 0
      end

      def file_path(key)
        md5hex = Digest::MD5.hexdigest(key);
        level1 = md5hex[-1]
        level2 = md5hex[-3, 2]
        return ::File.join(@dir, level1, level2, md5hex)
      end

    end

  end

end
