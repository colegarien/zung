defmodule Zung.PubSub do
  def subscribe(channel) do
    :gproc.reg({:p, :l, channel})
  end

  def unsubscribe(channel) do
    :gproc.unreg({:p, :l, channel})
  end

  def publish(channel, message) do
    :gproc.send({:p, :l, channel}, {self(), channel, message})
  end
end
