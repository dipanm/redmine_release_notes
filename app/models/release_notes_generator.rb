# Copyright (C) 2012-2013 Harry Garrood
# This file is a part of redmine_release_notes.

# redmine_release_notes is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.

# redmine_release_notes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.

# You should have received a copy of the GNU General Public License along with
# redmine_release_notes. If not, see <http://www.gnu.org/licenses/>.

class ReleaseNotesGenerator
  # for previewing formats
  class MockVersion
    class MockIssueCollection
      class MockIssue
        class MockReleaseNote
          attr_reader :text
          def initialize(text)
            @text = text
          end
        end

        class MockThingWithName
          attr_reader :name
          def initialize(name)
            @name = name
          end
        end

        attr_reader :subject, :tracker, :project, :id

        def initialize(opts)
          opts.each { |k, v| instance_variable_set :"@#{k}", v }
        end

        def release_note; MockReleaseNote.new(@release_note); end
        def tracker; MockThingWithName.new(@tracker); end
        def project; MockThingWithName.new(@project); end
      end

      def release_notes_done; self; end

      # yields all the MockIssues to the passed block
      def find_each(&blk)
        [
          MockIssue.new(:subject => 'Crashes on startup',
            :tracker => 'Bug',
            :release_note => 'Startup crashes no longer occur.',
            :project => 'Recipes app',
            :id => 37),
          MockIssue.new(:subject => 'Star recipes',
            :tracker => 'Feature',
            :release_note => 'Favourite recipes can now be starred.',
            :project => 'Recipes app',
            :id => 23),
          MockIssue.new(:subject => 'Better performance when saving recipes',
            :tracker => 'Feature',
            :release_note => 'Performance improved when saving recipes.',
            :project => 'Recipes app',
            :id => 15)
        ].each(&blk)
      end
    end

    def fixed_issues; MockIssueCollection.new; end
    def name; '1.0.0'; end
    def id; 8; end
    def description; 'Release candidate'; end
    def effective_date; Date.tomorrow; end
  end

  include Redmine::I18n # for format_date

  attr_reader :format, :version

  def initialize(version, format)
    @version = version
    @format = format
  end

  def generate
    generate_header << "\n" << generate_release_notes
  end

  private
  def generate_header
    make_substitutions(format.header, values_for_header(version))
  end

  def generate_release_notes
    str = format.start
    str << "\n"
    version.fixed_issues.release_notes_done.find_each do |issue|
      str << make_substitutions(format.each_issue, values_for_issue(issue))
      str << "\n"
    end
    str << format.end
  end

  # hash of values for the release notes header
  def values_for_header(version)
    {
      "name" => version.name,
      "date" => format_date(version.effective_date),
      "description" => version.description,
      "id" => version.id
    }
  end

  # hash of values for the release notes for a single issue
  def values_for_issue(issue)
    {
      "subject" => issue.subject,
      "release_notes" => issue.release_note ? issue.release_note.text : "",
      "tracker" => issue.tracker.name,
      "project" => issue.project.name,
      "id" => issue.id
    }
  end

  # given a string containing placeholders like %{this} and a hash mapping
  # placeholders to values, substitute placeholders for values
  def make_substitutions(string, subs)
    string.gsub(/%\{.*?\}/) do |match|
      subs[match[2..-2]] || match[2..-2]
    end
  end
end
