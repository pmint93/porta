#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/multi_route'

require 'uri'
require 'net/http'
require 'json'
require 'resolv'
require 'semian'

require 'byebug'

require './lib/to_query'

set :server, :thin  # or webrick, mongrel

set :bind, '0.0.0.0'

ALLOWED_VERSIONS = %w{ v1 v2 }

helpers do
  def version_compatible?(version)
    ALLOWED_VERSIONS.include? version
  end
  def lookup_service(service_name)
    if ENV['MOCKED'] == 'true' || ENV['MOCKED_IP'] || ENV['MOCKED_PORT']
      [ ENV['MOCKED_IP'] || '127.0.0.1', ENV['MOCKED_PORT'] || '3000']
    else
      resolver = Resolv::DNS.open
      record = resolver.getresource(service_name, Resolv::DNS::Resource::IN::SRV)
      return resolver.getaddress(record.target), record.port
    end
  end
  def generate_error(error_message, status = 422 )
    [ status, { 'Content-Type' => 'application/json' }, { error: error_message }.to_json ]
  end
  def generate_response(body, headers, status = 200 )
    [ status, { 'Content-Type' => 'application/json' }.merge(headers || {}), body.is_a?(Hash) ? body.to_json : body ]
  end
end

route :get, :post, :put, :patch, :delete, '/api/:version/:service/?*' do
  if version_compatible?(params[:version])
    begin
      address, port = lookup_service(params[:service])
      response = Net::HTTP.new(address.to_s, port).start do |api|
        api.use_ssl = request.secure?
        api.verify_mode = OpenSSL::SSL::VERIFY_NONE
        # Create request
        case request.request_method.upcase
        when 'GET', 'DELETE'
          r_path = '/api/' + params[:version] + '/' + params[:splat].last
          r_path += ('?' + request.params.to_query) if request.params.any?
          r = Net::HTTP.const_get(request.request_method.capitalize).new(r_path)
        when 'POST', 'PUT', 'PATCH'
          r = Net::HTTP.const_get(request.request_method.capitalize).new(r_path)
          r.set_form_data(request.params)
        else
          # None
        end
        # Set request headers
        r.add_field('User-Agent', request.user_agent)
        r.add_field('Content-Type', request['CONTENT_TYPE'])
        r.add_field('X-Forwarded-For', request.ip)
        r.add_field('Authorization', request['HTTP_AUTHORIZATION']) if request['HTTP_AUTHORIZATION']
        # Send request
        api.request(r)
        # byebug
      end
      response_headers = {}
      response.each_header do |k, v|
        response_headers[k] = v if k.downcase != 'transfer-encoding'
      end
      response_body = response.body
      response_code = response.code.to_i
      # Replace remote service's address with this service's address
      response_body.gsub!(
        "#{request.scheme}#{address     }:#{port        }/api/#{params[:version]}",
        "#{request.scheme}#{request.host}:#{request.port}/api/#{params[:version]}/#{params[:service]}"
      )
      generate_response(response_body, response_headers, response_code)
    rescue Resolv::ResolvError => ex
      generate_error(ex.message, 404)
    end
  else
    generate_error('Version not compatible with this server')
  end
end
