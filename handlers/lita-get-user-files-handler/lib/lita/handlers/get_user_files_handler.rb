#coding: utf-8

require 'slack'
require 'logger'

module Lita
  module Handlers
    class GetUserFilesHandler < Handler
        config :token
        config :logfile
        config :logrotate
        route /get_files/, :response_user_files_list, help: {"get_files" => "resopnse all your files list." }

        def response_user_files_list(response)
            #namespaceを特定するため、::Loggerで実装
            logger = ::Logger.new(config.logfile, config.logrotate)
            logger.info(self.class.name + " Executed by " + response.user.name)

            #Slack Clientを取得
            client = Slack::RPC::Client.new(config.token)
            api_response = client.files.list()

            if api_response.status != 200 || api_response.body['ok'] != true then
                error_code = api_response.body['error'].to_s
                logger.error("files.list Execute Error! : " + error_code)
                response.reply("Somthing wrong : " + error_code)
                return
            end

            #取得したファイル情報の一覧をfilesにセット
            files = api_response.body['files']

            #ユーザIDが一致するファイルの一覧を返す
            res = "[作成日時] ファイルID ファイル名"
            files.each do | file |
                if file['user'] == response.user.id then
                    res += "\n[" + Time.at(file['created']).strftime("%Y/%m/%d %H:%M").to_s + "] " + file['id'].to_s + " " + file['name'].to_s
                end
            end

            logger.info(res)
            response.reply(res)
        end
    end

    Lita.register_handler(GetUserFilesHandler)
  end
end
