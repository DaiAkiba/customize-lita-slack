#coding: utf-8

require 'slack'
require 'logger'
require 'date'
require_relative '../helper/slack_files_helper.rb'
require_relative '../helper/slack_users_helper.rb'

module Lita
  module Handlers
    class GetUserFilesHandler < Handler
        config :token
        config :logfile
        config :logrotate
        # get file list
        route /^getfl/,
               :response_file_list,
               command: true,
               kwargs: {
                   date: { short: "d", default: Time.now.strftime("%Y%m%d") },
                   user: { short: "u" }
               },
               help: {"getfl" => I18n.t("lita.handlers.help.getfl") }
        # delete file list
        route /^delfl/,
               :response_deleted_file_list,
               command: true,
               kwargs: {
                   date: { short: "d", default: Time.now.strftime("%Y%m%d") },
                   user: { short: "u" }
               },
               help: {"delfl" => I18n.t("lita.handlers.help.delfl") }

        def initialize( args )
            super args
            #namespaceを特定するため、::Loggerで実装
            @logger = ::Logger.new(config.logfile, config.logrotate)
        end

        # summary
        # パラメータで指定したユーザのファイルのうち、パラメータで指定した日付以前のファイル一覧を
        # レスポンスとして返す
        # @param Lita::Response Object
        def response_file_list(response)
            return response.reply(I18n.t("lita.handlers.errors.invalid_date_param")) unless setup_parameters?(response)

            @logger.info("GetFile Executed by #{response.user.name} about #{@user}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list?(fileList, response)

            #ユーザ一覧を取得
            userList = Array.new
            return unless get_user_list?(userList, response)

            userId = ''

            #ユーザ名が一致するユーザIDを返す
            userList.each do | user |
                if user['name'] == @user then
                    userId = user['id']
                    @logger.info("UserID: #{userId}")
                    break
                end
            end

            #ユーザIDが一致するファイルの一覧を返す
            response_files(fileList, userId, response)
        end

        # summary
        # パラメータで指定したユーザのファイルのうち、パラメータで指定した日付以前のファイルを削除し、
        # 削除したファイル一覧をレスポンスとして返す
        # @param Lita::Response Object
        def response_deleted_file_list(response)
            return response.reply(I18n.t("lita.handlers.errors.invalid_date_param")) unless setup_parameters?(response)
            
            @logger.info("DeleteFile Executed by #{response.user.name} about #{@user}")

            #ファイル一覧を取得
            fileList = Array.new
            return unless get_file_list?(fileList, response)

            #ユーザ一覧を取得
            userList = Array.new
            return unless get_user_list?(userList, response)

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
        def setup_parameters?(response)
            @logger.info("Date Params #{response.extensions[:kwargs][:date]}")
            @logger.info("User Params #{response.extensions[:kwargs][:user]}")

            # dateパラメータをチェック
            date_param = response.extensions[:kwargs][:date]
            return false unless validate_date_parameter?(date_param)

            @unix_date = Time.parse(date_param.slice(0,4) + "-" + date_param.slice(4,2) + "-" + date_param.slice(6,2)).to_i

            if response.extensions[:kwargs][:user].nil? then
                # パラメータ指定なしの場合は実行ユーザが対象
                @user = response.user.name
            else
                @user = response.extensions[:kwargs][:user]
            end
            true
        end

        def validate_date_parameter?(date_param)
            Date.valid_date?(date_param.slice(0,4).to_i,date_param.slice(4,2).to_i,date_param.slice(6,2).to_i)
        end

        def get_file_list?(file_list, response)
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

        def get_user_list?(user_list, response)
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

        def response_files(file_list, user_id, response)
            #ユーザIDが一致するファイルの一覧を返す
            res = I18n.t("lita.handlers.response.getfl", {user_name: @user})
            file_list.each do | file |
                if file['user'] == user_id and file['created'] <= @unix_date then
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
            res = I18n.t("lita.handlers.response.delfl")
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
