class Admin::CsecController < Admin::AdminController
  before_filter :authorize_csec

  def select_classes
    # If a klass has a coursesurvey, then it should be surveyed
    current_semester = Property.get_or_create.semester
    #@klasses = Klass.joins(:course).where('klasses.semester' => current_semester).order('courses.prefix, CAST(courses.course_number AS integer), courses.course_number, courses.suffix ASC')
    @klasses = Klass.current_semester
  end

  def select_classes_post
    Klass.current_semester.each do |klass|
      if params.has_key?("klass#{klass.id}") and klass.coursesurvey.nil?
        # This should not fail
        Coursesurvey.create!(:klass => klass)
      elsif !params.has_key?("klass#{klass.id}") and !klass.coursesurvey.nil?
        klass.coursesurvey.delete
      end
    end
    prop = Property.get_or_create
    prop.coursesurveys_active = !params[:coursesurveys_active].blank?
    prop.save
    redirect_to(admin_csec_select_classes_path, :notice => "Updated classes to be surveyed")
  end

  def manage_classes
    @coursesurveys = Coursesurvey.current_semester
  end

  def manage_classes_post
    params.keys.reject{|x| !(x =~ /^survey[0-9]*$/)}.each do |param_id|
      id = param_id[6..-1]
      coursesurvey = Coursesurvey.find(id)
      # This should not fail
      coursesurvey.update_attributes(params[param_id])
      if !coursesurvey.valid?
        redirect_to(admin_csec_manage_classes_path, :notice => "Error happened. Your input was probably not valid.")
        return
      end
    end
    redirect_to(admin_csec_manage_classes_path, :notice => "Updated classes")
  end

  def manage_candidates
    @people = Person.current_candidates
  end
end