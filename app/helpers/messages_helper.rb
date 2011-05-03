module MessagesHelper
  MARKDOWN_ALIASES = %w{ markdown md }
  YOUTUBE_POSTER_FRAME = 'http://img.youtube.com/vi/%s/0.jpg'
  
  MULTILINE = /\n/m
  
  URL_PROTOCOL = 'https*:\/\/'
  ANY_URL = /(#{URL_PROTOCOL}.+?)(\s|\)|\.\s|\.$|$)/i
  ONLY_URL = /^#{URL_PROTOCOL}[^\s]+$/i
  IMAGE_URL = /\.(gif|png|jpe?g)\??/i
  YOUTUBE_URL = /^#{URL_PROTOCOL}\w*\.*youtube.com\/watch.+?v=([\w-]+)/i
  
  URL_PROTOCOL_SIZE = 'https://'.size
  TRUNCATE_URL = 50
  
  def timestamp_message_needed?(message)
    @last_message.nil? || @last_message.created_at < (message.created_at - TIMESTAMP_MESSAGE_INTERVAL)
  end
  
  def authors_name_needed?(message)
    @last_message.nil? || @last_message.author != message.author
  end
  
  def open_link_to(content, url, options = {})
    link_to content, url, options.merge(:target => '_blank')
  end
  
  def link_to_messages_on_date(date, direction)
    if date
      path = room_messages_on_day_path(@room, :day => date)
      link = open_link_to(date.to_formatted_s(:long_ordinal), path)
      direction == :previous ? '← ' + link : link + ' →'
    end
  end
  
  def format_message_timestamp(message)
    created_at = message.created_at
    authors_created_at = created_at.in_time_zone(message.author.time_zone)
    if @authenticated.time_zone == message.author.time_zone
      return format_timestamp(created_at)
    else
      s = format_timestamp(created_at)
      s << " ("
      s << authors_created_at.strftime("%d %b %H:%M")
      s << ")"
      return s
    end
  end
  
  def format_timestamp(timestamp, time_zone = nil)
    if params[:q]
      open_link_to(timestamp.strftime("%d %b %Y %H:%M"), room_messages_on_day_path(@room, :day => timestamp.to_date))
    else
      timestamp.strftime("%H:%M")
    end
  end
  
  def format_message(message)
    if message.attachment_message?
      format_attachment_message(message)
    else
      case body = message.body.strip
      when ONLY_URL
        format_special_link(body)
      when MULTILINE
        format_multiline_message(message.body)
      end
    end || format_links(body)
  end
  
  def markdown(text)
    RDiscount.new(text).to_html.strip
  end
  
  def format_multiline_message(raw_body)
    if raw_body =~ /^syntax:(\w+)\n(.+)$/m
      syntax, body = $1, $2
      if MARKDOWN_ALIASES.include?(syntax)
        "<div class=\"code\">#{markdown(body)}</div>"
      else
        "<pre class=\"brush: #{syntax}\">#{h(body)}</pre>"
      end
    else
      "<pre class=\"code\">#{h(raw_body)}</pre>"
    end
  end
  
  def format_links(body)
    only_url = (body =~ ONLY_URL)
    
    h(body).gsub(ANY_URL) do
      url, remainder = $1, $2
      
      content = if only_url
        url
      else
        if url.length > TRUNCATE_URL
          protocol = url.match(URL_PROTOCOL)[0]
          host = url[protocol.length..-1].split('/').first
          "#{protocol}#{host}…"
        else
          url
        end
      end
      
      "#{link_to(content, url, :target => '_blank')}#{remainder}"
    end
  end
  
  def format_special_link(url)
    case url
    when YOUTUBE_URL
      open_link_to(image_tag(YOUTUBE_POSTER_FRAME % $1, :alt => ''), url)
    when IMAGE_URL
      open_image_link(url)
    end
  end
  
  def format_attachment_message(message)
    path = message.attachment.original.public_path
    path =~ IMAGE_URL ? open_image_link(path) : open_link_to(h(message.body), path)
  end
  
  def open_image_link(url)
    open_link_to(image_tag(url, :alt => ''), url)
  end
  
  def format_full_name(member)
    name = h(member.full_name)
    parts = name.split(' ')
    return name if parts.length == 1
    parts[0..-2].join(' ') + parts.last
    "#{parts[0..-2].join(' ')} #{parts.last[0,1]}."
  end
end
