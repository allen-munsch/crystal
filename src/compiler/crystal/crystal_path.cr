require "./config"

module Crystal
  struct CrystalPath
    def self.default_path
      ENV["CRYSTAL_PATH"]? || Crystal::Config.path
    end

    @crystal_path : Array(String)

    def initialize(path = CrystalPath.default_path, target_triple = LLVM.default_target_triple)
      @crystal_path = path.split(':').reject &.empty?
      add_target_path(target_triple)
    end

    private def add_target_path(target_triple = LLVM.default_target_triple)
      triple = target_triple.split('-')
      triple.delete(triple[1]) if triple.size == 4 # skip vendor

<<<<<<< HEAD
      if %w(i386 i486 i586).includes?(triple[0])
        triple[0] = "i686"
      end

      target = if triple.any?(&.includes?("macosx"))
                 {triple[0], "macosx", "darwin"}.join('-')
               elsif triple.any?(&.includes?("freebsd"))
                 {triple[0], triple[1], "freebsd"}.join('-')
               else
                 triple.join('-')
               end

      @crystal_path.each do |path|
        _path = File.join(path, "lib_c", target)
        if Dir.exists?(_path)
          @crystal_path << _path unless @crystal_path.includes?(_path)
          return
        end
      end
=======
    def initialize(path = DEFAULT_PATH)
      path = Dir.working_directory + "#{File::SEPARATOR}src" if path.length == 0
      @crystal_path = path.split(File::PATH_SEPARATOR)
>>>>>>> refs/remotes/origin/windows
    end

    def find(filename, relative_to = nil)
      relative_to = File.dirname(relative_to) if relative_to.is_a?(String)
      if filename.starts_with?('.')
        result = find_in_path_relative_to_dir(filename, relative_to)
      else
        result = find_in_crystal_path(filename, relative_to)
      end
      result = [result] if result.is_a?(String)
      result
    end

    private def find_in_path_relative_to_dir(filename, relative_to, check_crystal_path = true)
      if relative_to.is_a?(String)
        # Check if it's a wildcard.
        if filename.ends_with?("/*") || (recursive = filename.ends_with?("/**"))
          filename_dir_index = filename.rindex('/').not_nil!
          filename_dir = filename[0..filename_dir_index]
<<<<<<< HEAD
          relative_dir = "#{relative_to}/#{filename_dir}"
=======
          ifdef darwin || linux
            relative_dir = "#{relative_to}#{File::SEPARATOR}#{filename_dir}"
          elsif windows
            filename_dir = filename_dir[2...filename_dir.length] if filename_dir.starts_with?("./")
            filename_dir = filename_dir[0...filename_dir.length - 1] if filename_dir.ends_with?('/')
            relative_dir = filename_dir.length > 0 ? "#{relative_to}#{File::SEPARATOR}#{filename_dir.tr("/", "\\")}" : relative_to
          end
>>>>>>> refs/remotes/origin/windows
          if File.exists?(relative_dir)
            files = [] of String
            gather_dir_files(relative_dir, files, recursive)
            return files
          end
        else
          ifdef darwin || linux
            relative_filename = "#{relative_to}#{File::SEPARATOR}#{filename}"
          elsif windows
            filename = filename[2...filename.length] if filename.starts_with?("./")
            relative_filename = "#{relative_to}#{File::SEPARATOR}#{filename.tr("/", "\\")}"
          end

          # Check if .cr file exists.
          relative_filename_cr = relative_filename.ends_with?(".cr") ? relative_filename : "#{relative_filename}.cr"
          if File.exists?(relative_filename_cr)
            return make_relative_unless_absolute relative_filename_cr
          end

          # If it's a directory, we check if a .cr file with a name the same as the
          # directory basename exists, and we require that one.
          if Dir.exists?(relative_filename)
            basename = File.basename(relative_filename)
            absolute_filename = make_relative_unless_absolute("#{relative_filename}#{File::SEPARATOR}#{basename}.cr")
            if File.exists?(absolute_filename)
              return absolute_filename
            end
          end
        end
      end

      if check_crystal_path
        find_in_crystal_path filename, relative_to
      else
        nil
      end
    end

    private def gather_dir_files(dir, files_accumulator, recursive)
      files = [] of String
      dirs = [] of String

      Dir.foreach(dir) do |filename|
        full_name = "#{dir}#{File::SEPARATOR}#{filename}"

        if File.directory?(full_name)
          if filename != "." && filename != ".." && recursive
            dirs << filename
          end
        else
          if filename.ends_with?(".cr")
            files << full_name
          end
        end
      end

      files.sort!
      dirs.sort!

      files.each do |file|
        ifdef darwin || linux
          files_accumulator << File.expand_path(file)
        elsif windows
          files_accumulator << file
        end
      end

      dirs.each do |subdir|
        gather_dir_files("#{dir}#{File::SEPARATOR}#{subdir}", files_accumulator, recursive)
      end
    end

    private def make_relative_unless_absolute(filename)
<<<<<<< HEAD
      filename = "#{Dir.current}/#{filename}" unless filename.starts_with?('/')
      File.expand_path(filename)
=======
      ifdef darwin || linux
        filename = "#{Dir.working_directory}#{File::SEPARATOR}#{filename}" unless filename.starts_with?('/')
        File.expand_path(filename)
      elsif windows
        File.expand_path(filename)
      end
>>>>>>> refs/remotes/origin/windows
    end

    private def find_in_crystal_path(filename, relative_to)
      @crystal_path.each do |path|
        required = find_in_path_relative_to_dir(filename, path, check_crystal_path: false)
        return required if required
      end

      if relative_to
        raise "can't find file '#{filename}' relative to '#{relative_to}'"
      else
        raise "can't find file '#{filename}'"
      end
    end
  end
end
