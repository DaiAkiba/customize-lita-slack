#coding: utf-8

class SlackApiHelper
    attr_accessor :error_code

    private
    def initialize
        @error_code = ''
    end

    def check_api_response(api_response)
        ret = true
        ret = false if api_response.status != 200 || api_response.body['ok'] != true
        ret
    end
end
