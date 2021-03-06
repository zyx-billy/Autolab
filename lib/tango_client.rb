require "httparty"
require "cgi"
require Rails.root.join("config", "autogradeConfig.rb")

##
# Ruby API Client of Tango
module TangoClient
  # Httparty client for Tango API
  class ClientObj
    include HTTParty
    base_uri "#{RESTFUL_HOST}:#{RESTFUL_PORT}"
    default_timeout 30
  end

  # Exception for Tango API Client
  class TangoException < StandardError; end

  def self.handle_exceptions
    resp = yield
    if resp.content_type == "application/json" && resp["statusId"] && resp["statusId"] < 0
      fail TangoException, "Tango returned negative status code."
    end
    return resp
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise TangoException, "Connection timed out with Tango."
  rescue StandardError => e
    raise TangoException, "Unexpected error with Tango (#{e})."
  end

  # Why does handle_exceptions throw an exception????? Ever????
  # handle_exceptions throws an exception when the returned statusId is negative,
  # which is weird because the caller seems to expect negative statusIds to
  # be successfully returned. Anyway, I'll fix that.
  def self.handle_exceptions_allowing_negative_statusId
    resp = yield
    return resp
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise TangoException, "Connection timed out with Tango."
  rescue StandardError => e
    raise TangoException, "Unexpected error with Tango (#{e})."
  end

  def self.open(courselab)
    resp = handle_exceptions do
      url = "/open/#{api_key}/#{courselab}/"
      ClientObj.get(url)
    end
    resp["files"]
  end

  def self.upload(courselab, filename, file)
    handle_exceptions do
      url = "/upload/#{api_key}/#{courselab}/"
      ClientObj.post(url, headers: { "filename" => filename }, body: file)
    end
  end

  def self.addjob(courselab, options = {})
    handle_exceptions do
      url = "/addJob/#{api_key}/#{courselab}/"
      ClientObj.post(url, body: options)
    end
  end

  def self.cancel(courselab, output_file)
    handle_exceptions_allowing_negative_statusId do
      url = "/cancel/#{api_key}/#{courselab}/#{output_file}/"
      ClientObj.post(url)
    end
  end

  def self.poll(courselab, output_file, in_progress = 0)
    handle_exceptions do
      url = "/poll/#{api_key}/#{courselab}/#{output_file}/?inprogress=#{in_progress}"
      ClientObj.get(url)
    end
  end

  def self.info
    resp = handle_exceptions do
      url = "/info/#{api_key}/"
      ClientObj.get(url)
    end
    resp["info"]
  end

  def self.jobs(deadjobs = 0)
    resp = handle_exceptions do
      url = "/jobs/#{api_key}/#{deadjobs}/"
      ClientObj.get(url)
    end
    resp["jobs"]
  end

  def self.pool(image = nil)
    resp = handle_exceptions do
      url = image.nil? ? "/pool/#{api_key}/" : "/pool/#{api_key}/#{image}/"
      ClientObj.get(url)
    end
    resp
  end

  def self.prealloc(image, num, options = {})
    handle_exceptions do
      url = "/prealloc/#{api_key}/#{image}/#{num}/"
      ClientObj.post(url, body: options, timeout: 0)
    end
  end

  def self.scale(min, max)
    handle_exceptions do
      url = "/scale/#{api_key}/#{min}/#{max}/"
      ClientObj.post(url)
    end
  end

  def self.api_key
    RESTFUL_KEY
  end
end
