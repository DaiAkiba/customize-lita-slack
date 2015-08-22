#coding: utf-8

require 'slack'
require 'logger'
require_relative '../helper/slack_files_helper.rb'
require_relative '../helper/slack_users_helper.rb'

module Lita
  module Handlers
    class GetUserFilesHandler < Handler
        config :token
        config :logfile
        config :logrotate
        # get file list
        route /^getfl/, :response_user_files_list, help: {"getfl" => "resopnse all your files list." }
        # get someone's file list
        route /^getsfl\s+(.+)/, :response_someones_files_list
        # delete file list
        route /^delfl/, :response_deleted_files_list, help: {"delfl" => "delete all your files." }
        # delete someone's file list
        route /^delsfl\s+(.+)/, :response_deleted_someones_files_list


        def initialize( args )
            super args
            #namespaceを特定するため、::Loggerで実装
            @logger = ::Logger.new(config.logfile, config.logrotate)
        end

        def response_user_files_list(response)
            @logger.info("GetFiles Executed by #{response.user.name}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list(fileList, response)

            #ユーザIDが一致するファイルの一覧を返す
            response_files(fileList, response.user.id, response.user.name, response)
        end

        def response_someones_files_list(response)
            @logger.info("GetSomeone'sFiles Executed by #{response.user.name} about #{response.matches[0][0]}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list(fileList, response)

            #ユーザ一覧を取得
            userList = Array.new
            return unless get_user_list(userList, response)

            userId = ''

            #ユーザ名が一致するユーザIDを返す
            userList.each do | user |
                if user['name'] == response.matches[0][0] then
                    userId = user['id']
                    @logger.info("UserID: #{userId}")
                    break
                end
            end

            #ユーザIDが一致するファイルの一覧を返す
            response_files(fileList, userId, response.matches[0][0], response)
        end

        def response_deleted_files_list(response)
            @logger.info("DeleteFiles Executed by #{response.user.name}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list(fileList, response)

            #ユーザIDが一致するファイルを削除して一覧を返す
            response_deleted_files(fileList, response.user.id, response)
        end

        def response_deleted_someones_files_list(response)
            @logger.info("DeleteSomeone'sFiles Executed by #{response.user.name} about #{response.matches[0][0]}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list(fileList, response)

            #ユーザ一覧を取得
            userList = Array.new
            return unless get_user_list(userList, response)

            userId = ''

            #ユーザ名が一致するユーザIDを返す
            userList.each do | user |
                if user['name'] == response.matches[0][0] then
                    userId = user['id']
                    @logger.info("UserID: #{userId}")
                    break
                end
            end

            #ユーザIDが一致するファイルを削除して一覧を返す
            response_deleted_files(fileList, userId, response)
        end

        private
        def get_file_list(file_list, response)
            #Slack Clientを取得
            client = Slack::RPC::Client.new(config.token)

            #ファイル一覧を取得
            file_helper = SlackFilesHelper.new()
            list = file_helper.getList(client)
            if file_helper.error_code.empty? then
                file_list.concat(list)
                true
            else
                @logger.error("files.list Execute Error! : #{file_helper.error_code}")
                response.reply("Something wrong : #{file_helper.error_code}")
                false
            end
        end

        def get_user_list(user_list, response)
            #Slack Clientを取得
            client = Slack::RPC::Client.new(config.token)

            #ユーザ一覧を取得
            user_helper = SlackUsersHelper.new()
            list = user_helper.getList(client)
            if user_helper.error_code.empty? then
                user_list.concat(list)
                true
            else
                @logger.error("users.list Execute Error! : #{user_helper.error_code}")
                response.reply("Something wrong : #{user_helper.error_code}")
                false
            end
        end

        def response_files(file_list, user_id, user_name, response)
            #ユーザIDが一致するファイルの一覧を返す
            res = "#{user_name}は以下のファイルを保存しています\n[作成日時] ファイルID ファイル名"
            file_list.each do | file |
                if file['user'] == user_id then
                    res += "\n[#{Time.at(file['created']).strftime("%Y/%m/%d %H:%M").to_s}] #{file['id'].to_s} #{file['name'].to_s}"
                end
            end
            @logger.info(res)
            response.reply(res)
        end

        def response_deleted_files(file_list, user_id, response)
            #Slack Clientを取得
            client = Slack::RPC::Client.new(config.token)
            file_helper = SlackFilesHelper.new()

            #ユーザIDが一致するファイルを削除して一覧を返す
            res = "以下のファイルを削除しました\n[作成日時] ファイルID ファイル名"
            file_list.each do | file |
                if file['user'] == user_id then
                    result = file_helper.deleteFile(client, file['id'].to_s)
                    @logger.info("files.delete Execute Result : ID[" + file['id'].to_s + "] Result[#{file_helper.error_code}]")
                    res += "\n[" + Time.at(file['created']).strftime("%Y/%m/%d %H:%M").to_s + "] " + file['id'].to_s + " " + file['name'].to_s
                end
            end
            @logger.info(res)
            response.reply(res)
        end

    end

    Lita.register_handler(GetUserFilesHandler)
  end
end
