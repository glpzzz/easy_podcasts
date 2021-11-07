defmodule EasypodcastsWeb.ChannelLive.Show do
  use EasypodcastsWeb, :live_view
  alias Easypodcasts.Channels.DataProcess

  alias Easypodcasts.Channels

  # @impl true
  # def mount(_params, _session, socket) do
  #   {:ok, socket}
  # end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    [id | _] = String.split(slug, "-")

    channel = Channels.get_channel!(id)

    socket =
      socket
      |> assign(:channel, channel)
      |> assign(:page_title, "#{channel.title}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("process_episode", %{"episode_id" => episode_id}, socket) do
    episode = Channels.get_episode!(episode_id)

    socket =
      if episode.status == :new do
        # TODO: Move this from here
        DataProcess.process_episode(episode)

        msg =
          Enum.random([
            "Sit and relax",
            "Go grab a drink",
            "Do some stretching"
          ])

        socket
        # TODO: Don't fetch the channel again, just the episode that changed
        |> update(:channel, fn _ -> Channels.get_channel!(socket.assigns.channel.id) end)
        |> put_flash(:info, "The episode is in queue. #{msg}")
      else
        put_flash(socket, :error, "Sorry. That episode can't be processed right now")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:episode_processed, %{channel_id: channel_id, episode_title: episode_title}},
        socket
      ) do
    socket =
      socket
      |> put_flash(:success, "The episode '#{episode_title}' was processed successfully")
      |> update(:channel, fn _ -> Channels.get_channel!(channel_id) end)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:queue_changed, socket) do
    send_update(EasypodcastsWeb.QueueComponent, id: "queue_state")
    {:noreply, socket}
  end

  defp format_date(date) do
    localized = DateTime.shift_zone!(date, "America/Havana")
    "#{localized.year}/#{localized.month}/#{localized.day} #{localized.hour}:#{localized.minute}"
  end

  defp format_duration(duration) when is_binary(duration) do
    cond do
      String.contains?(duration, ":") -> duration
      true -> format_duration(String.to_integer(duration))
    end
  end

  defp format_duration(duration) when is_integer(duration) do
    time = Time.new!(0, 0, 0) |> Time.add(duration)
    "#{time.hour}:#{time.minute}:#{time.second}"
  end
end
