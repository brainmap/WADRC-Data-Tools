
	class Jobs::ASL::Vgroup < Vgroup

		def related_enrollment

			if enrollments.count == 0
				return nil
			elsif enrollments.count == 1
            	enrollments.first
          	elsif enrollments.count > 1
	            if !primary_enumber.blank?
	              enrollments.select{|enr| enr.enumber == primary_enumber}.first
	            else
	              nil
	            end
	        else
	        	nil
	        end
		end

		def related_scan_procedure

			if scan_procedures.count == 0
				return nil
			elsif scan_procedures.count == 1
            	scan_procedures.first
          	elsif scan_procedures.count > 1
	            if !primary_scan_procedure.blank?
	              scan_procedures.select{|sp| sp.codename == primary_scan_procedure}.first
	            else
	              nil
	            end
	        else
	        	nil
	        end
        end

	end
