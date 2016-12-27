defmodule PaperTrail.VersionQueries do
  import Ecto.Query
  alias PaperTrail.Version

  @doc """
  Gets all the versions of a record given a module and its id
  """
  def get_versions(repo, model, id) do
    item_type = model |> Module.split |> List.last
    version_query(item_type, id) |> repo.all
  end

  @doc """
  Gets all the versions of a record
  """
  def get_versions(repo, record) do
    item_type = record.__struct__ |> Module.split |> List.last
    version_query(item_type, record.id) |> repo.all
  end

  @doc """
  Gets the last version of a record given its module reference and its id
  """
  def get_version(repo, model, id) do
    item_type = Module.split(model) |> List.last
    last(version_query(item_type, id)) |> repo.one
  end

  @doc """
  Gets the last version of a record
  """
  def get_version(repo, record) do
    item_type = record.__struct__ |> Module.split |> List.last
    last(version_query(item_type, record.id)) |> repo.one
  end

  @doc """
  Gets the current record of a version
  """
  def get_current(repo, version) do
    repo.get("Elixir." <> version.item_type |> String.to_existing_atom, version.item_id)
  end


  defp version_query(item_type, id) do
    from v in Version,
    where: v.item_type == ^item_type and v.item_id == ^id
  end
end
