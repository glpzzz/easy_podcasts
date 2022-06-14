defmodule Easypodcasts do
  @moduledoc """
  Easypodcasts keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  import Ecto.Query
  alias Easypodcasts.Repo
  alias Easypodcasts.Channels.Channel
  alias Easypodcasts.Episodes.Episode
  alias Easypodcasts.Workers.Worker

  def get_channels_stats() do
    channels = Repo.one(from(c in Channel, select: count(c)))
    episodes = Repo.one(from(e in Episode, select: count(e)))

    size_stats =
      Repo.one(
        from(e in Episode,
          where: e.status == :done,
          select: %{
            total: count(e),
            original: sum(e.original_size),
            processed: sum(e.processed_size)
          }
        )
      )

    workers =
      Repo.all(
        from(w in Worker,
          left_join: e in assoc(w, :episodes),
          group_by: w.id,
          select_merge: %{episodes: count(w.id)}
        )
      )

    {channels, episodes, size_stats, workers}
  end
end
