<<<<<<< HEAD
require "c/dirent"
require "c/unistd"
require "c/sys/stat"
=======
lib LibC
  ifdef darwin || linux
    type Dir = Void*

    ifdef darwin
      struct DirEntry
        d_ino : Int32
        reclen : UInt16
        type : UInt8
        namelen : UInt8
        name : UInt8[1024]
      end
    elsif linux
     struct DirEntry
        d_ino : UInt64
        d_off : Int64
        reclen : UInt16
        type : UInt8
        name : UInt8[256]
      end
    end

    ifdef darwin
      struct Glob
        pathc : LibC::SizeT
        matchc : Int32
        offs : LibC::SizeT
        flags : Int32
        pathv : UInt8**
        dummy : UInt8[48]
      end
    elsif linux
      struct Glob
        pathc : LibC::SizeT
        pathv : UInt8**
        offs : LibC::SizeT
        flags : Int32
        dummy : UInt8[40]
      end
    end

    ifdef darwin
      enum GlobFlags
        APPEND = 1 << 0
        BRACE  = 1 << 7
        TILDE  = 1 << 11
      end
    elsif linux
      enum GlobFlags
        APPEND = 1 << 5
        BRACE  = 1 << 10
        TILDE  = 1 << 12
      end
    end

    enum GlobErrors
      NOSPACE = 1
      ABORTED = 2
      NOMATCH = 3
    end

    fun opendir(name : UInt8*) : Dir*
    fun closedir(dir : Dir*) : Int32
    ifdef darwin
      fun readdir(dir : Dir*) : DirEntry*
    elsif linux
      fun readdir = readdir64(dir : Dir*) : DirEntry*
    end

    fun getcwd(buffer : UInt8*, size : Int32) : UInt8*
    fun chdir(path : UInt8*) : Int32

    fun mkdir(path : UInt8*, mode : LibC::ModeT) : Int32
    fun rmdir(path : UInt8*) : Int32

    fun glob(pattern : UInt8*, flags : GlobFlags, errfunc : (UInt8*, Int32) -> Int32, result : Glob*) : Int32
    fun globfree(result : Glob*)
  elsif windows
    MAX_DRIVE = 3
    MAX_FNAME = 256
    MAX_DIR   = MAX_FNAME
    MAX_EXT   = MAX_FNAME
    MAX_PATH  = 260

    struct WFindData
      attrib : UInt32
      time_create : Int64
      time_access : Int64
      time_write : Int64
      size : Int64
      name : UInt16[260]
    end

    fun wfindfirst = _wfindfirst64(path : UInt16*, info : WFindData*) : IntT
    fun findclose = _findclose(handle : IntT) : Int32
    fun wfindnext = _wfindnext64(handle : IntT, info : WFindData*) : Int32

    fun wgetcwd = _wgetcwd(buffer : UInt16*, size : Int32) : UInt16*
    fun wchdir = _wchdir(path : UInt16*) : Int32

    fun wmkdir = _wmkdir(path : UInt16*) : Int32
    fun wrmdir = _wrmdir(path : UInt16*) : Int32
    fun wsplitpath = _wsplitpath(path : UInt16*, drive : UInt16*, dir : UInt16*, fname : UInt16*, ext : UInt16*)
  end
end
>>>>>>> refs/remotes/origin/windows

# Objects of class Dir are directory streams representing directories in the underlying file system.
# They provide a variety of ways to list directories and their contents. See also `File`.
#
# The directory used in these examples contains the two regular files (config.h and main.rb),
# the parent directory (..), and the directory itself (.).
class Dir
  include Enumerable(String)
  include Iterable

  getter path : String

  # Returns a new directory object for the named directory.
  def initialize(@path)
<<<<<<< HEAD
    @dir = LibC.opendir(@path.check_no_null_byte)
    unless @dir
      raise Errno.new("Error opening directory '#{@path}'")
=======
    ifdef darwin || linux
      @dir = LibC.opendir(@path)
      unless @dir
        raise Errno.new("Error opening directory '#{@path}'")
      end
    elsif windows
      case
      when @path.ends_with?("\\*")
      when @path.ends_with?('\\')
        @path = @path + '*'
      else
        @path = "#{@path}\\*"
      end
      @handle = LibC.wfindfirst(@path.to_utf16, out @info)
      if @handle == -1
        raise Errno.new("Error opening directory '#{@path}'")
      else
        @first = true
      end
>>>>>>> refs/remotes/origin/windows
    end
    @closed = false
  end

  # Alias for `new(path)`
  def self.open(path) : self
    new path
  end

  # Opens a directory and yields it, closing it at the end of the block.
  # Returns the value of the block.
  def self.open(path)
    dir = new path
    begin
      yield dir
    ensure
      dir.close
    end
  end

  # Calls the block once for each entry in this directory,
  # passing the filename of each entry as a parameter to the block.
  #
  # ```
  # d = Dir.new("testdir")
  # d.each { |x| puts "Got #{x}" }
  # ```
  #
  # produces:
  #
  # ```text
  # Got .
  # Got ..
  # Got config.h
  # Got main.rb
  # ```
  def each
    while entry = read
      yield entry
    end
  end

  def each
    EntryIterator.new(self)
  end

  # Reads the next entry from dir and returns it as a string. Returns nil at the end of the stream.
  #
  # ```
  # d = Dir.new("testdir")
  # d.read # => "."
  # d.read # => ".."
  # d.read # => "config.h"
  # ```
  def read
<<<<<<< HEAD
    # readdir() returns NULL for failure and sets errno or returns NULL for EOF but leaves errno as is.  wtf.
    Errno.value = 0
    ent = LibC.readdir(@dir)
    if ent
      String.new(ent.value.d_name.to_unsafe)
    elsif Errno.value != 0
      raise Errno.new("readdir")
    else
      nil
=======
    ifdef darwin || linux
      ent = LibC.readdir(@dir)
      if ent
        String.new(ent.value.name.buffer)
      else
        nil
      end
    elsif windows
      if @first || LibC.wfindnext(@handle, out @info) == 0
        @first = false
        String.new(@info.name.buffer)
      else
        nil
      end
>>>>>>> refs/remotes/origin/windows
    end
  end

  # Repositions this directory to the first entry.
  def rewind
    LibC.rewinddir(@dir)
    self
  end

  # Closes the directory stream.
  def close
<<<<<<< HEAD
    return if @closed
    if LibC.closedir(@dir) != 0
      raise Errno.new("closedir")
    end
    @closed = true
  end

  # Returns the current working directory.
  def self.current : String
    if dir = LibC.getcwd(nil, 0)
      String.new(dir).tap { LibC.free(dir.as(Void*)) }
    else
      raise Errno.new("getcwd")
    end
  end

  # Changes the current working directory of the process to the given string.
  def self.cd(path)
    if LibC.chdir(path.check_no_null_byte) != 0
      raise Errno.new("Error while changing directory to #{path.inspect}")
=======
    ifdef darwin || linux
      LibC.closedir(@dir)
    elsif windows
      LibC.findclose(@handle)
    end
  end

  def self.working_directory
    ifdef darwin || linux
      dir = LibC.getcwd(nil, 0)
    elsif windows
      dir = LibC.wgetcwd(nil, 0)
    end
    String.new(dir).tap { LibC.free(dir as Void*) }
  end

  # Changes the current working directory of the process to the given string.
  def self.chdir(path)
    ifdef darwin || linux
      status = LibC.chdir(path)
    elsif windows
      status = LibC.wchdir(path.to_utf16)
    end
    if status != 0
      raise Errno.new("Error while changing directory")
>>>>>>> refs/remotes/origin/windows
    end
  end

  # Changes the current working directory of the process to the given string
  # and invokes the block, restoring the original working directory
  # when the block exits.
  def self.cd(path)
    old = current
    begin
<<<<<<< HEAD
      cd(path)
      yield
    ensure
      cd(old)
    end
  end

=======
      chdir path
      yield
    ensure
      chdir old
    end
  end

  # Alias for `chdir`.
  def self.cd(path)
    chdir path
  end

>>>>>>> refs/remotes/origin/windows
  # Calls the block once for each entry in the named directory,
  # passing the filename of each entry as a parameter to the block.
  def self.foreach(dirname)
    Dir.open(dirname) do |dir|
      dir.each do |filename|
        yield filename
      end
    end
  end

  # Returns an array containing all of the filenames in the given directory.
  def self.entries(dirname) : Array(String)
    entries = [] of String
    foreach(dirname) do |filename|
      entries << filename
    end
    entries
  end

<<<<<<< HEAD
  # Returns true if the given path exists and is a directory
  def self.exists?(path) : Bool
    if LibC.stat(path.check_no_null_byte, out stat) != 0
      if Errno.value == Errno::ENOENT || Errno.value == Errno::ENOTDIR
        return false
      else
        raise Errno.new("stat")
      end
=======
  ifdef darwin || linux
    def self.[](*patterns)
      glob(patterns)
    end

    def self.[](patterns : Enumerable(String))
      glob(patterns)
    end

    def self.glob(*patterns)
      glob(patterns)
    end

    def self.glob(*patterns)
      glob(patterns) do |pattern|
        yield pattern
      end
    end

    def self.glob(patterns : Enumerable(String))
      paths = [] of String
      glob(patterns) do |path|
        paths << path
      end
      paths
    end

    def self.glob(patterns : Enumerable(String))
      paths = LibC::Glob.new
      flags = LibC::GlobFlags::BRACE | LibC::GlobFlags::TILDE
      errfunc = -> (_path : UInt8*, _errno : Int32) { 0 }

      patterns.each do |pattern|
        result = LibC.glob(pattern, flags, errfunc, pointerof(paths))

        if result == LibC::GlobErrors::NOSPACE
          raise GlobError.new "Ran out of memory"
        elsif result == LibC::GlobErrors::ABORTED
          raise GlobError.new "Read error"
        end

        flags |= LibC::GlobFlags::APPEND
      end

      Slice(UInt8*).new(paths.pathv, paths.pathc.to_i32).each do |path|
        yield String.new(path)
      end

      nil
    ensure
      LibC.globfree(pointerof(paths))
    end
  end

  def self.exists?(path)
    ifdef darwin || linux
      status = LibC.stat(path, out stat)
    elsif windows
      status = LibC.wstat(path.to_utf16, out stat)
    end
    if status != 0
      return false
>>>>>>> refs/remotes/origin/windows
    end
    File::Stat.new(stat).directory?
  end

<<<<<<< HEAD
  # Creates a new directory at the given path. The linux-style permission mode
  # can be specified, with a default of 777 (0o777).
  def self.mkdir(path, mode = 0o777)
    if LibC.mkdir(path.check_no_null_byte, mode) == -1
=======
  def self.mkdir(path, mode=0777)
    ifdef darwin || linux
      status = LibC.mkdir(path, LibC::ModeT.cast(mode))
    elsif windows
      status = LibC.wmkdir(path.to_utf16)
    end
    if status == -1
>>>>>>> refs/remotes/origin/windows
      raise Errno.new("Unable to create directory '#{path}'")
    end
    0
  end

  # Creates a new directory at the given path, including any non-existing
  # intermediate directories. The linux-style permission mode can be specified,
  # with a default of 777 (0o777).
  def self.mkdir_p(path, mode = 0o777)
    return 0 if Dir.exists?(path)

    components = path.split(File::SEPARATOR)
    if components.first == "." || components.first == ""
      subpath = components.shift
    else
      subpath = "."
    end

    components.each do |component|
      subpath = File.join subpath, component

      mkdir(subpath, mode) unless Dir.exists?(subpath)
    end

    0
  end

  # Removes the directory at the given path.
  def self.rmdir(path)
<<<<<<< HEAD
    if LibC.rmdir(path.check_no_null_byte) == -1
=======
    ifdef darwin || linux
      status = LibC.rmdir(path)
    elsif windows
      status = LibC.wrmdir(path.to_utf16)
    end
    if status == -1
>>>>>>> refs/remotes/origin/windows
      raise Errno.new("Unable to remove directory '#{path}'")
    end
    0
  end

  def to_s(io)
    io << "#<Dir:" << @path << ">"
  end

  # :nodoc:
  struct EntryIterator
    include Iterator(String)

    @dir : Dir

    def initialize(@dir)
    end

    def next
      @dir.read || stop
    end

    def rewind
      @dir.rewind
      self
    end
  end
end

require "./dir/*"
