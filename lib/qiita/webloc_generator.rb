require 'qiita/webloc_generator/version'
require 'qiita'
require 'plist'

module Qiita
  class WeblocGenerator
    attr_reader :team, :access_token

    def initialize(team:, access_token:)
      @team = team
      @access_token = access_token
    end

    def generate
      puts "Generating weblocs into #{webloc_directory.inspect}..."

      in_webloc_directory do
        each_items_page.with_index do |response, index|
          puts "Processing items of page #{index + 1}..."

          response.body.each do |item|
            filename = normalize_filename(item['title'])
            create_webloc(filename, item['url'])
          end
        end
      end

      puts 'Done.'
    end

    private

    def webloc_directory
      @webloc_directory ||= "#{team}_weblocs"
    end

    def in_webloc_directory(&block)
      Dir.mkdir(webloc_directory) unless Dir.exist?(webloc_directory)
      Dir.chdir(webloc_directory, &block)
    end

    def each_items_page
      return to_enum(__method__) unless block_given?

      response = qiita_client.list_items(page: 1, per_page: 100)
      yield response

      while response.next_page_url
        response = qiita_client.get(response.next_page_url)
        yield response
      end
    end

    def qiita_client
      @qiita_client ||= Qiita::Client.new(team: team, access_token: access_token)
    end

    def normalize_filename(filename)
      filename.tr('/', ':')
    end

    def create_webloc(filename, url)
      plist = { 'URL' => url }.to_plist
      File.write("#{filename}.webloc", plist)
    end
  end
end
