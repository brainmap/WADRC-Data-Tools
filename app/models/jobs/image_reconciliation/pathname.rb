class Jobs::ImageReconciliation::Pathname < Pathname
  MIN_PFILE_SIZE = 10_000_000
  
  def each_subdirectory
    each_entry do |leaf|
      next if leaf.to_s =~ /^\./
      branch = self + leaf
      next if not branch.directory?
      next if branch.symlink?
      branch.each_subdirectory { |subbranch| yield subbranch }
      yield branch
    end
  end
  
  def each_pfile(min_file_size = MIN_PFILE_SIZE)
    #puts "in each_pfile"
    #puts "core_additions each_pfile ==> local_copy"
    entries.each do |leaf|
      next unless leaf.to_s =~ /^P.{5}\.7(\.bz2)/
      branch = self + leaf
      next if branch.symlink?
      if branch.size >= min_file_size
        # check for P*.7.summary 
        # if there, skip local_copy of P*.7.bz2
       leaf_summary_s = (leaf.to_s).gsub(/\.bz2/,"")+".summary"
       branch_summary_s = self.to_s+"/"+leaf_summary_s
       if File.exist?(branch_summary_s)
            branch_summary_pn = Pathname.new(branch_summary_s)
            lc = branch_summary_pn
           # summary_lc.delete
       else
        lc = branch
       end
        begin
          yield lc
        rescue StandardError => e
          case $LOG.level
          when Logger::DEBUG
            raise e
          else
            puts "#{e}"
          end
        end
      end
    end
  end

    def each_pfile_non_bz2(min_file_size = MIN_PFILE_SIZE)
      # not using the P*.7.summary --- should be bzip2'ed
    entries.each do |leaf|
      next unless leaf.to_s =~ /^P.{5}(\.7)$/
      branch = self + leaf
      next if branch.symlink?
      if branch.size >= min_file_size
        begin
          yield branch
        rescue StandardError => e
          case $LOG.level
          when Logger::DEBUG
            raise e
          else
            puts "#{e}"
          end
        end
      end
    end
  end


    def each_pfile_summary(min_file_size = MIN_PFILE_SIZE)
    entries.each do |leaf|
      next unless leaf.to_s =~ /^P.{5}(\.7\.summary)/
      branch = self + leaf
      next if branch.symlink?
      if branch.size >= min_file_size
        begin
          yield branch
        rescue StandardError => e
          case $LOG.level
          when Logger::DEBUG
            raise e
          else
            puts "#{e}"
          end
        end
      end
    end
  end

  
  def first_dicom
    entries.each do |leaf|
      branch = self + leaf
      if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/
        begin
          yield branch
        rescue Exception => e
          puts "#{e}"
        end
        return
      end 
    end
  end
  
  def all_dicoms
    dicoms = []
    # Dir.mktmpdir do |tempdir|
      begin
        entries.each do |leaf|
          branch = self + leaf
          if leaf.to_s =~ /^I\.(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]+(\.bz2)?$/
            dicoms << branch
          end
        end

        yield dicoms

    end
    
    return
  end
  
  
end