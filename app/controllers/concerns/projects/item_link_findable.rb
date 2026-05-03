# frozen_string_literal: true

module Projects
  module ItemLinkFindable
    extend ActiveSupport::Concern

    URL_PREFIX_PATTERN = %r{\Ahttps?://}
    MR_URL_PATTERN = %r{/(?<full_path>.+)/-/merge_requests/(?<iid>\d+)\z}
    ISSUE_URL_PATTERN = %r{/(?<full_path>.+)/-/issues/(?<iid>\d+)\z}

    private

    def find_target(reference)
      return nil if reference.blank?

      ref = reference.to_s.strip

      if ref =~ URL_PREFIX_PATTERN
        find_target_by_url(ref)
      elsif ref.start_with?(MergeRequest.reference_prefix)
        @project.merge_requests.find_by(iid: ref.delete_prefix(MergeRequest.reference_prefix).to_i)
      elsif ref.start_with?(Issue.reference_prefix)
        @project.namespace.issues.find_by(iid: ref.delete_prefix(Issue.reference_prefix).to_i)
      end
    end

    def find_target_by_url(url_string)
      uri = URI.parse(url_string)
      return nil unless uri.host == request.host && uri.port == request.port

      path = uri.path
      if (m = MR_URL_PATTERN.match(path))
        project = Project.find_by_full_path(m[:full_path])
        project&.merge_requests&.find_by(iid: m[:iid].to_i)
      elsif (m = ISSUE_URL_PATTERN.match(path))
        project = Project.find_by_full_path(m[:full_path])
        project&.namespace&.issues&.find_by(iid: m[:iid].to_i)
      end
    rescue URI::InvalidURIError
      nil
    end

    def render_link_error(message)
      flash.now[:alert] = message
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash'), status: :unprocessable_entity }
      end
    end

    def render_duplicate_flash
      render_link_error(_('This item is already linked.'))
    end

    def issue_reference?(q)
      q.start_with?(Issue.reference_prefix)
    end

    def mr_reference?(q)
      q.start_with?(MergeRequest.reference_prefix)
    end

    def search_link_item_results(q)
      return [] if q.blank?

      issues = @project.issues_visible_to(current_user)
      mrs = @project.merge_requests

      if issue_reference?(q)
        Array(issues.find_by(iid: q.delete_prefix(Issue.reference_prefix).to_i))
      elsif mr_reference?(q)
        Array(mrs.find_by(iid: q.delete_prefix(MergeRequest.reference_prefix).to_i))
      else
        issues.ransack(title_cont: q).result.limit(3).to_a +
          mrs.ransack(title_cont: q).result.limit(3).to_a
      end
    end
  end
end
