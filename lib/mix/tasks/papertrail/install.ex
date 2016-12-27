defmodule Mix.Tasks.Papertrail.Install do
  @shortdoc "generates paper_trail migration file for your database"

  import Macro, only: [underscore: 1]
  import Mix.Ecto
  import Mix.Generator

  use Mix.Task

  def run(args) do
    repo = args |> parse_repo |> List.first
    ensure_repo(repo, args)

    path = Path.relative_to(migrations_path(repo), Mix.Project.app_path)
    file = Path.join(path, "#{timestamp()}_#{underscore(AddVersions)}.exs")
    create_directory path

    assigns = [mod: Module.concat([repo, Migrations, AddVersions])]

    create_file file, migration_template(assigns)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration

    def change do
      create table(:versions) do
        add :event,        :string
        add :item_type,    :string
        add :item_id,      :integer
        add :item_changes, :map
        add :meta,         :map

        add :inserted_at,  :datetime, null: false
      end
    end
  end
  """
end
