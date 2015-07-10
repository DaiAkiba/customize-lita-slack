#coding: utf-8

require 'slack'
require 'logger'

module Lita
  module Handlers
    class HelloHandler < Handler
        config :token
        #route /^file\s+(.+)/, :with_file, help: {"file TEXT" => "reply back with java."}
        route /latest_file/, :with_file, help: {"file TEXT" => "reply back with java."}

        def with_file( response )
            p "Debug Message"
            p "Args:" + response.args.to_s
            p "User:" + response.user.name
            p "User:" + response.user.id
            p "Message:" + response.message.body
            # namespaceを特定するために::Loggerで処理
            log = ::Logger.new(STDOUT)
            log.info("Handling with_java")


            #word = response.matches[0][0]
            #response.reply("!!! #{word} とジャヴァ!!!")
            
            log.info("Token:" + config.token)
            client = Slack::RPC::Client.new(config.token)
            api_response = client.files.list()
            log.info("Status:" + api_response.status.to_s)
            log.info("Result:" + api_response.body['ok'].to_s)
            if api_response.status == 200 && api_response.body['ok'] != true then
                log.info("Result:" + api_response.body['error'].to_s)
            end
            files = api_response.body['files']
            log.info("Result:" + files[0].to_s)
            log.info("Result:" + files[0]['id'].to_s)
            #response.reply(files[0]['id'].to_s + ":" + files[0]['name'].to_s)

            res = String.new
            files.each do |file|
                if (file['user'] == response.user.id) then
                    res += "\r\n" + file['id'].to_s + ":" + file['name'].to_s
                    p file['id']
                    #break
                end
            end

            response.reply(res)

            #result = JSON.parse(api_response.body)
            #api_response = client.files.list()
            #parsed = result['files']
            #parsed.each do |file|
            #    log.info(file.id)
            #end
        end
    end

    Lita.register_handler(HelloHandler)
  end
end
