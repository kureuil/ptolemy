defmodule TequilaWeb.ChannelView do
  use TequilaWeb, :view

  def link_host(location) do
    uri = URI.parse(location)
    uri.host
  end
end
