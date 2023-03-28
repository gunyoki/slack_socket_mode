# frozen_string_literal: true

require_relative "slackbot_lite/version"
require "cgi"
require "json"
require "faraday"
require "websocket_client_lite"

class SlackbotLite
  attr_accessor :slack_app_token, :logger, :websocket

  def initialize(slack_app_token, logger: nil)
    @slack_app_token = slack_app_token
    @logger = logger || Logger.new(File::NULL)
  end

  def open(debug_reconnects: false)
    ws_url = fetch_websocket_url(@slack_app_token)
    ws_url = add_query_to_url(ws_url, debug_reconnects: true) if debug_reconnects
    @websocket = WebsocketClientLite.new(ws_url, logger: @logger)
    @websocket.handshake
  end

  def each_payload(&block)
    @websocket.each_payload do |ws_payload|
      data = JSON.parse(ws_payload, symbolize_names: true)
      case data[:type].to_sym
      when :hello
        @logger.debug("[slackbot] hello")
      when :events_api
        @logger.debug("[slackbot] events_api")
        if data[:envelope_id]
          body = { envelope_id: data[:envelope_id] }.to_json
          @websocket.send_text(body)
        end
        payload = data[:payload]
        next if payload.dig(:event, :hidden)

        block.yield(payload)
      when :disconnect
        @logger.debug("[slackbot] disconnect")
        @websocket.close
      else
        @logger.error("[slackbot] Unknown type: #{data[:type]}")
      end
    end
  end

  def normalize_text(text)
    unescape_slack_text(text).unicode_normalize(:nfkc).strip
  end

  def unescape_slack_text(text)
    text = text.gsub(/<([?@#!]?)(.*?)>/) { |matched|
      dt = matched[1]
      _link, label = dt.split("|", 2)
      label.to_s
    }
    CGI.unescape_html(text)
  end

  private

  def fetch_websocket_url(app_token)
    api_client = Faraday.new("https://slack.com/api/") { |faraday|
      faraday.request :authorization, "Bearer", app_token
      faraday.request :json
      faraday.response :json
      faraday.response :raise_error
    }

    response = api_client.post("apps.connections.open")
    body = response.body

    if body["ok"]
      body["url"]
    else
      @logger.error("Cannot generate an WebSocket URL: #{body['error']}")
      nil
    end
  end

  def add_query_to_url(url, query)
    uri = URI(url)
    hash = URI.decode_www_form(uri.query.to_s).to_h
    query.each do |key, value|
      hash[key.to_s] = value
    end
    uri.query = URI.encode_www_form(hash)
    uri.to_s
  end
end
