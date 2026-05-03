# frozen_string_literal: true

module API
  module V4
    class ProjectBaseController < ::API::V4::UserBaseController
      include API::V4::ProjectFindable

      skip_before_action :authenticate!
      prepend_before_action :find_project!
      before_action :authenticate_unless_public_read!

      private

      def authenticate_unless_public_read!
        authenticate! unless @project&.public? && request.get?
      end
    end
  end
end
