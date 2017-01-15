class EducatorsController < ApplicationController
  # Authentication by default inherited from ApplicationController.

  before_action :authenticate_districtwide_access!, only: [
    :districtwide_admin_homepage, :bulk_services_upload
  ]

  def homepage
    redirect_to homepage_path_for_role(current_educator)
  end

  def districtwide_admin_homepage
    @elementary_schools = School.where(school_type: ['ES', 'ESMS'])
  end

  def bulk_services_upload
    @serialized_data = { service_uploads: ServiceUpload.all.as_json(
      only: [:created_at, :file_name],
      include: {
        services: {
          only: [],
          include: {
            student: {
              only: [:first_name, :last_name, :id]
            }
          }
        }
      })
    }
  end

  def names_for_dropdown
    student = Student.find(params[:id])
    school = student.school

    if school.nil?
      render json: [] and return
    end

    render json: filtered_names(params[:term], school)
  end

  def reset_session_clock
    # Send arbitrary request to reset Devise Timeoutable

    respond_to do |format|
      format.json { render json: :ok }
    end
  end

  def authenticate_districtwide_access!
    unless current_educator.districtwide_access
      redirect_to not_authorized_path
    end
  end

  private

  def filtered_names(term, school)
    unfiltered = (school.educator_names_for_services + Service.provider_names).uniq.compact

    return unfiltered.sort_by(&:downcase) if term.nil?  # Handle missing param

    filtered = unfiltered.select do |name|
      split_name = name.split(', ')   # SIS name format expected
      split_name.any? { |name_part| match?(term, name_part) } || match?(term, name)
    end

    return filtered.sort_by(&:downcase)
  end

  def match?(term, string_to_test)
    term.downcase == string_to_test.slice(0, term.length).downcase
  end

end
