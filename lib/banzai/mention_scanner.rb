# frozen_string_literal: true

module Banzai
  # Walks a CommonMarker AST looking for @username mentions in :text nodes,
  # skipping any text already inside a :link (autolinked emails/URLs, [text](url)).
  # Resolves matches to real Users in a single batched query, and splices
  # resolved mentions into the AST as :inline_html link nodes.
  class MentionScanner
    EXTENSIONS = %i[table strikethrough autolink tagfilter tasklist].freeze

    Result = Struct.new(:doc, :users, keyword_init: true)

    def self.scan(text)
      new(text).scan
    end

    def initialize(text)
      @text = text
    end

    def scan
      return Result.new(doc: nil, users: User.none) if text.blank?

      text_nodes = doc.walk.select { |node| node.type == :text && !within_link?(node) }
      usernames = text_nodes.flat_map { |node| node.string_content.scan(User.reference_pattern).flatten }.uniq

      return Result.new(doc: doc, users: User.none) if usernames.empty?

      users_by_username = User.by_username(usernames).index_by { |u| u.username.downcase }

      return Result.new(doc: doc, users: User.none) if users_by_username.empty?

      text_nodes.each { |node| splice_mentions!(node, users_by_username) }

      Result.new(doc: doc, users: users_by_username.values)
    end

    private

    attr_reader :text

    def doc
      @doc ||= CommonMarker.render_doc(text, :DEFAULT, EXTENSIONS)
    end

    def within_link?(node)
      ancestor = node.parent

      while ancestor
        return true if ancestor.type == :link

        ancestor = ancestor.parent
      end

      false
    end

    def splice_mentions!(node, users_by_username)
      content = node.string_content
      last_index = 0
      spliced = false

      content.to_enum(:scan, User.reference_pattern).each do
        match = Regexp.last_match
        user = users_by_username[match[:username].downcase]
        next unless user

        prefix = content[last_index...match.begin(0)]
        node.insert_before(text_node(prefix)) if prefix.present?
        node.insert_before(mention_node(user))
        last_index = match.end(0)
        spliced = true
      end

      return unless spliced

      remainder = content[last_index..]
      remainder.present? ? node.string_content = remainder : node.delete
    end

    def text_node(str)
      node = CommonMarker::Node.new(:text)
      node.string_content = str
      node
    end

    def mention_node(user)
      node = CommonMarker::Node.new(:inline_html)
      username = ERB::Util.html_escape(user.username)
      node.string_content = %(<a href="/#{username}" class="gfm gfm-project_member">@#{username}</a>)
      node
    end
  end
end
