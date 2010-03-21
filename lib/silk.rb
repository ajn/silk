module Silk

  # Many thanks to the guys at Rails Engines for this great method
  def self.mirror_files_from(source, destination)
    return unless File.directory?(source)

    # TODO: use Rake::FileList#pathmap?    
    source_files = Dir[source + "/**/*"]
    source_dirs = source_files.select { |d| File.directory?(d) }
    source_files -= source_dirs

    unless source_files.empty?
      base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
      FileUtils.mkdir_p(base_target_dir)
    end

    source_dirs.each do |dir|
      # strip down these paths so we have simple, relative paths we can
      # add to the destination
      target_dir = File.join(destination, dir.gsub(source, ''))
      begin        
        FileUtils.mkdir_p(target_dir)
      rescue Exception => e
        raise "Could not create directory #{target_dir}: \n" + e
      end
    end

    source_files.each do |file|
      begin
        target = File.join(destination, file.gsub(source, ''))
        unless File.exist?(target) && FileUtils.identical?(file, target)
          FileUtils.cp(file, target)
        end 
      rescue Exception => e
        raise "Could not copy #{file} to #{target}: \n" + e 
      end
    end

  end

end
