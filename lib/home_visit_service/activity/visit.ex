defmodule HomeVisitService.Activity.Visit do
  use Ecto.Schema
  import Ecto.Changeset
  alias HomeVisitService.{Accounts, Activity}
  alias HomeVisitService.Accounts.User

  schema "visits" do
    field :date, :utc_datetime
    field :minutes, :integer
    field :tasks, :string
    field :status, Ecto.Enum, values: [:pending, :accepted, :fulfilled]
    belongs_to :member_user, User, foreign_key: :member
    belongs_to :pal_user, User, foreign_key: :pal

    timestamps()
  end

  @doc """
  A changeset for creating a visit. A visit always has a status of :pending when it is created.
  If the visit date is in the past, an error is added
  If the visit minutes are more than the user's balance minus any requested visit minutes, an error is added
  """
  def changeset(visit, attrs) do
    visit
    |> cast(attrs, [:tasks, :minutes, :date, :member])
    |> validate_required([:tasks, :minutes, :date, :member])
    |> validate_date_in_future()
    |> force_change(:status, :pending)
    |> validate_available_balance()
  end

  @doc """
  A changeset for updating a visit. Only tasks, minutes, and date can be changed
  If the visit date is in the past, an error is added
  If the visit minutes are more than the user's balance minus any requested visit minutes, an error is added
  """
  def update_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:tasks, :minutes, :date])
    |> validate_required([:tasks, :minutes, :date])
    |> validate_date_in_future()
    |> validate_available_balance()
  end

  @doc """
  A changeset for updating the status and pal of a visit.
  The pal must be an existing user
  Status goes from :pending to :accepted to :fulfilled
  If the visit member is the same as the pal, an error is added
  """
  def status_changeset(visit, attrs) do
    visit
    |> cast(attrs, [:status, :pal])
    |> validate_required([:status, :pal])
    |> validate_exclusion(:pal, [visit.member], message: "pal can't be the member")
    |> validate_status()
    |> foreign_key_constraint(:pal)
  end

  defp validate_status(visit) do
    case {visit.data.status, get_change(visit, :status)} do
      {_status, nil} ->
        visit

      {:pending, :fulfilled} ->
        add_error(visit, :status, "visit must be accepted before it can be fulfilled")

      {:fulfilled, _} ->
        add_error(visit, :status, "visit has already been fulfilled")

      _ ->
        visit
    end
  end

  defp validate_available_balance(%{valid?: false} = changeset) do
    changeset
  end

  defp validate_available_balance(changeset) do
    user_id = get_field(changeset, :member)
    requested_balance = Activity.get_requested_visit_minutes(user_id)

    try do
      balance =
        user_id
        |> Accounts.get_user!()
        |> Map.get(:balance)

      if balance - requested_balance >= get_field(changeset, :minutes) do
        changeset
      else
        add_error(changeset, :minutes, "insufficient balance")
      end
    rescue
      Ecto.NoResultsError -> add_error(changeset, :member, "member not found")
    end
  end

  defp validate_date_in_future(changeset) do
    date = get_change(changeset, :date)

    if date != nil && DateTime.compare(date, DateTime.utc_now()) == :lt do
      add_error(changeset, :date, "must be in the future")
    else
      changeset
    end
  end
end
