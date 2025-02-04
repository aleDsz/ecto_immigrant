defmodule Mix.Tasks.EctoImmigrant.Gen.Migration do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto
  import Mix.EctoImmigrant

  @shortdoc "Generates a new data migration for the repo"

  @moduledoc """
  Generates a data migration.

  The repository must be set under `:ecto_repos` in the
  current app configuration.

  ## Examples

      mix ecto_immigrant.gen.migration add_admin_to_users_table

  The generated migration filename will be prefixed with the current
  timestamp in UTC which is used for versioning and ordering.

  By default, the migration will be generated to the
  "priv/YOUR_REPO/data_migrations" directory of the current application
  but it can be configured to be any subdirectory of `priv` by
  specifying the `:priv` key under the repository configuration.

  This generator will automatically open the generated file if
  you have `ECTO_EDITOR` set in your environment variable.

  ## Command line options

    * `-r`, `--repo` - the repo to generate migration for

  """

  @switches [change: :string]

  @doc false
  def run(args) do
    no_umbrella!("ecto_data.gen.migration")
    repos = parse_repo(args)

    Enum.each(repos, fn repo ->
      case OptionParser.parse(args, switches: @switches) do
        {opts, [name], _} ->
          ensure_repo(repo, args)
          path = data_migrations_path(repo)
          file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
          create_directory(path)

          assigns = [
            mod: Module.concat([repo, DataMigrations, camelize(name)]),
            change: opts[:change]
          ]

          create_file(file, data_migration_template(assigns))

          if open?(file) and Mix.shell().yes?("Do you want to run this migration?") do
            Mix.Task.run("ecto_data.migrate", [repo])
          end

        {_, _, _} ->
          Mix.raise(
            "expected ecto_data.gen.migration to receive the migration file name, " <>
              "got: #{inspect(Enum.join(args, " "))}"
          )
      end
    end)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:data_migration, """
  defmodule <%= inspect @mod %> do
    use EctoImmigrant.Migration

    def up do
  <%= @change %>
    end
  end
  """)
end
