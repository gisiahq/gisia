# frozen_string_literal: true

namespace :licenses do
  desc 'Regenerate .licenses/Gisia/others/gitlab-foss.dep.yml from gitlab-foss source'
  task :update_gitlab_foss do
    foss_path = Rails.root.join('../gitlab-foss')

    unless foss_path.exist?
      abort "gitlab-foss not found at #{foss_path}"
    end

    version = foss_path.join('VERSION').read.strip
    license_text = foss_path.join('LICENSE').read

    indented_license = license_text.lines.map { |l| l.rstrip.empty? ? '' : "    #{l}" }.join

    notice_path = foss_path.join('NOTICE')
    notices = if notice_path.exist?
      notice_text = notice_path.read
      indented_notice = notice_text.lines.map { |l| l.rstrip.empty? ? '' : "  #{l}" }.join
      "- sources: NOTICE\n  text: |2\n#{indented_notice}"
    else
      '[]'
    end

    content = <<~YAML
      ---
      name: gitlab-foss
      version: #{version}
      type: source
      summary: GitLab FOSS is a read-only mirror of GitLab, with all proprietary code removed.
      homepage: https://gitlab.com/gitlab-org/gitlab-foss
      license: mit
      licenses:
      - sources: LICENSE
        text: |2
      #{indented_license}
      notices: #{notices}
    YAML

    output_path = Rails.root.join('.licenses/Gisia/others/gitlab-foss.dep.yml')
    output_path.write(content)

    puts "Updated #{output_path} to gitlab-foss #{version}"
  end
end
