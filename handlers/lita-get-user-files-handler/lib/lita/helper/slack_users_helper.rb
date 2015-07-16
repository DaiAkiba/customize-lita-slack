#coding: utf-8

require 'slack'
require_relative './slack_api_helper.rb'

class SlackUsersHelper < SlackApiHelper
    def getList(client)
        #Slackのユーザ一覧を取得
        api_response = client.users.list()

        if check_api_response(api_response) then
            #取得したユーザ情報の一覧を返す
            api_response.body['members']
        else
            @error_code = api_response.body['error'].to_s
        end
    end
end
