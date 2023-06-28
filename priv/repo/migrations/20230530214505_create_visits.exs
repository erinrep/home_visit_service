defmodule HomeVisitService.Repo.Migrations.CreateVisits do
  use Ecto.Migration

  def change do
    create table(:visits) do
      add :tasks, :string, null: false
      add :minutes, :integer, null: false
      add :date, :utc_datetime, null: false
      add :status, :string, null: false, default: "pending"
      add :member, references(:users, on_delete: :nothing), null: false
      add :pal, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:visits, [:member])
    create index(:visits, [:pal])
  end
end
