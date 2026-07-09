# frozen_string_literal: true

namespace :gettext do
  desc 'Regenerate gisia.pot file from source code'
  task :regenerate do
    require 'gettext/tools'
    require 'gettext/tools/parser/ruby'
    require 'gettext/tools/parser/erb'
    require 'gettext/tools/msgmerge'

    ensure_locale_folder_presence!
    FileUtils.rm_f(pot_file_path)

    files = Dir.glob(Rails.root.join('{app,lib,config}/**/*.{rb,haml,erb}'))
    files.select! { |f| File.read(f).force_encoding('utf-8').include?('_(') rescue false }

    GetText::Tools::XGetText.run(*files, '--output', pot_file_path,
      '--package-name', 'gisia',
      '--package-version', '1.0.0',
      '--no-location')

    puts "POT file updated: #{pot_file_path}"

    Dir.glob(Rails.root.join('locale/*/gisia.po')).each do |po_file|
      GetText::Tools::MsgMerge.run(po_file, pot_file_path, '--output', po_file, '--no-obsolete-entries')
      puts "Synced: #{po_file}"
    end
  end

  desc 'Compile po files to Jed JSON for frontend usage'
  task :compile do
    require 'json'

    Dir.glob(Rails.root.join('locale/*/gisia.po')).each do |po_file|
      locale = File.basename(File.dirname(po_file))
      output_dir = Rails.root.join('app/assets/javascripts/locale', locale)
      FileUtils.mkdir_p(output_dir)

      jed_data = po_to_jed(po_file, locale, 'gisia')
      output_file = File.join(output_dir, 'app.js')
      File.write(output_file, "window.translations = #{JSON.generate(jed_data)};")
      puts "Compiled: #{output_file}"
    end
  end

  desc 'Lint all po files in locale/'
  task lint: :environment do
    files = Dir.glob(Rails.root.join('locale/*/gisia.po'))
    files.unshift(pot_file_path) if File.exist?(pot_file_path)

    errors_found = false

    files.each do |file|
      errors = lint_po_file(file)
      next if errors.empty?

      puts "Errors in #{file}:"
      errors.each { |e| puts "  #{e}" }
      errors_found = true
    end

    if errors_found
      raise 'PO file lint failed'
    else
      puts 'All PO files are valid.'
    end
  end

  private

  def pot_file_path
    @pot_file_path ||= Rails.root.join('locale/gisia.pot').to_s
  end

  def ensure_locale_folder_presence!
    locale_path = Rails.root.join('locale')
    raise "Cannot find '#{locale_path}' folder." unless Dir.exist?(locale_path)
  end

  def po_to_jed(po_file, locale, domain)
    entries = {}
    msgid = nil
    msgid_plural = nil
    msgstr = []
    in_msgstr = false

    File.readlines(po_file, encoding: 'utf-8').each do |line|
      line = line.chomp

      if line.start_with?('msgid ')
        if msgid && !msgstr.empty?
          key = msgid_plural ? "#{msgid_plural}\u0004#{msgid}" : msgid
          entries[key] = [msgid_plural].compact + msgstr
        end
        msgid = unescape_po(line.sub(/^msgid /, ''))
        msgid_plural = nil
        msgstr = []
        in_msgstr = false
      elsif line.start_with?('msgid_plural ')
        msgid_plural = unescape_po(line.sub(/^msgid_plural /, ''))
      elsif line =~ /^msgstr(\[\d+\])? /
        in_msgstr = true
        msgstr << unescape_po(line.sub(/^msgstr(\[\d+\])? /, ''))
      elsif line.start_with?('"') && in_msgstr
        msgstr[-1] = (msgstr[-1] || '') + unescape_po(line)
      elsif line.start_with?('"') && msgid
        msgid += unescape_po(line)
      end
    end

    if msgid && !msgstr.empty?
      key = msgid_plural ? "#{msgid_plural}\u0004#{msgid}" : msgid
      entries[key] = [msgid_plural].compact + msgstr
    end

    plural_forms = entries.dig('', 0) || "nplurals=2; plural=(n != 1);"

    {
      domain: domain,
      locale_data: {
        domain => {
          '' => {
            domain: domain,
            plural_forms: plural_forms,
            lang: locale
          }
        }.merge(entries.reject { |k, _| k.empty? })
      }
    }
  end

  def unescape_po(str)
    str.gsub(/^"/, '').gsub(/"$/, '')
      .gsub('\\n', "\n")
      .gsub('\\t', "\t")
      .gsub('\\"', '"')
      .gsub('\\\\', '\\')
  end

  def lint_po_file(file)
    errors = []
    File.readlines(file, encoding: 'utf-8').each_with_index do |line, i|
      errors << "Line #{i + 1}: invalid encoding" unless line.valid_encoding?
    end
    errors
  end
end
