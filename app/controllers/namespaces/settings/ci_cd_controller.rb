# frozen_string_literal: true

module Namespaces
  module Settings
    class CiCdController < Namespaces::Settings::ApplicationController
      before_action :authorize_admin_group_runners!

      def update
        settings = @namespace.namespace_settings || @namespace.build_namespace_settings

        if settings.update(ci_cd_params)
          redirect_to namespace_settings_runners_path(@namespace.full_path),
            notice: _('CI/CD settings were successfully updated.')
        else
          redirect_to namespace_settings_runners_path(@namespace.full_path),
            alert: settings.errors.full_messages.join(', ')
        end
      end

      private

      def authorize_admin_group_runners!
        head :forbidden unless can?(current_user, :admin_group_runners, @namespace)
      end

      def ci_cd_params
        @ci_cd_params ||= params.require(:namespace_setting).permit(:shared_runners_enabled)
      end
    end
  end
end
