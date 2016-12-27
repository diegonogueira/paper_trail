defmodule PaperTrail do

  defmacro __using__(opts) do
    quote do
      @repo_version unquote(opts[:repo_version])

      @before_compile PaperTrail
    end
  end

  defmacro __before_compile__(env) do
    repo_client = env.module
    repo_version = Module.get_attribute(env.module, :repo_version) || repo_client

    quote do
      alias PaperTrail.VersionQueries
      alias Ecto.Multi
      alias PaperTrail.Version

      @doc """
      Gets all the versions of a record given a module and its id
      """
      def get_versions(model, id) do
        VersionQueries.get_versions(unquote(repo_version), model, id)
      end

      @doc """
      Gets all the versions of a record
      """
      def get_versions(record) do
        VersionQueries.get_versions(unquote(repo_version), record)
      end

      @doc """
      Gets the last version of a record given its module reference and its id
      """
      def get_version(model, id) do
        VersionQueries.get_version(unquote(repo_version), model, id)
      end

      @doc """
      Gets the last version of a record
      """
      def get_version(record) do
        VersionQueries.get_version(unquote(repo_version), record)
      end

      @doc """
      Gets the current record of a version
      """
      def get_current(version) do
        VersionQueries.get_current(unquote(repo_version), version)
      end

      @doc """
      Inserts a record to the database with a related version insertion in one transaction
      """
      def insert_and_version(changeset, meta \\ nil) do
        Multi.new
        |> Multi.insert(:model, changeset)
        |> Multi.run(:version, fn %{model: model} ->
          version = make_version_struct(%{event: "create"}, model, meta)
          unquote(repo_version).insert(version)
        end)
        |> unquote(repo_client).transaction
      end

      @doc """
      Updates a record from the database with a related version insertion in one transaction
      """
      def update_and_version(changeset, meta \\ nil) do
        Multi.new
        |> Multi.update(:model, changeset)
        |> Multi.run(:version, fn %{model: _model} ->
          version = make_version_struct(%{event: "update"}, changeset, meta)
          unquote(repo_version).insert(version)
        end)
        |> unquote(repo_client).transaction
      end

      @doc """
      Deletes a record from the database with a related version insertion in one transaction
      """
      def delete_and_version(struct, meta \\ nil) do
        Multi.new
        |> Multi.delete(:model, struct)
        |> Multi.run(:version, fn %{model: model} ->
          version = make_version_struct(%{event: "destroy"}, model, meta)
          unquote(repo_version).insert(version)
        end)
        |> unquote(repo_client).transaction
      end

      defp make_version_struct(%{event: "create"}, model, meta) do
        %Version{
          event: "create",
          item_type: model.__struct__ |> Module.split |> List.last,
          item_id: model.id,
          item_changes: filter_item_changes(model),
          meta: meta
        }
      end

      defp make_version_struct(%{event: "update"}, changeset, meta) do
        %Version{
          event: "update",
          item_type: changeset.data.__struct__ |> Module.split |> List.last,
          item_id: changeset.data.id,
          item_changes: changeset.changes,
          meta: meta
        }
        end

      defp make_version_struct(%{event: "destroy"}, model, meta) do
        %Version{
          event: "destroy",
          item_type: model.__struct__ |> Module.split |> List.last,
          item_id: model.id,
          item_changes: filter_item_changes(model),
          meta: meta
        }
      end

      defp filter_item_changes(model) do
        relationships = model.__struct__.__schema__(:associations)

        Map.drop(model, [:__struct__, :__meta__] ++ relationships)
      end
    end
  end
end
