defmodule HomeVisitService.Activity do
  @moduledoc """
  The Activity context.
  """

  import Ecto.Query, warn: false
  alias HomeVisitService.{Helpers, Repo}

  alias HomeVisitService.Activity.Visit
  alias HomeVisitService.Accounts.User

  @spec list_pending_visits :: nil | [%{optional(atom) => any}] | %{optional(atom) => any}
  @doc """
  Returns the list of pending visits with member preloaded.

  ## Examples

      iex> list_pending_visits()
      [%Visit{}, ...]

  """
  def list_pending_visits do
    Visit
    |> where([visit], visit.status == :pending)
    |> Repo.all()
    |> Repo.preload(:member_user)
  end

  @doc """
  Returns the list of visits where the given user is a member.

  ## Examples

      iex> list_visits_by_member(1)
      [%Visit{}, ...]

  """
  def list_visits_by_member(user_id) do
    Visit
    |> where([visit], visit.member == ^user_id)
    |> Repo.all()
    |> Repo.preload(:pal_user)
  end

  @doc """
  Returns the total minutes of all unfulfilled visits for the given user.

  ## Examples

      iex> get_requested_visit_minutes(1)
      [%Visit{}, ...]

  """
  def get_requested_visit_minutes(user_id) do
    Visit
    |> where([visit], visit.member == ^user_id)
    |> where([visit], visit.status != :fulfilled)
    |> Repo.all()
    |> Enum.reduce(0, fn v, acc -> acc + v.minutes end)
  end

  @doc """
  Returns the list of visits where the given user is a pal.

  ## Examples

      iex> list_visits_by_pal(1)
      [%Visit{}, ...]

  """
  def list_visits_by_pal(user_id) do
    Visit
    |> where([visit], visit.pal == ^user_id)
    |> Repo.all()
    |> Repo.preload(:member_user)
  end

  @doc """
  Gets a single visit.

  Raises `Ecto.NoResultsError` if the Visit does not exist.

  ## Examples

      iex> get_visit!(123)
      %Visit{}

      iex> get_visit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_visit!(id) do
    Visit
    |> Repo.get!(id)
    |> Repo.preload(:member_user)
    |> Repo.preload(:pal_user)
  end

  @doc """
  Creates a visit.

  ## Examples

      iex> create_visit(%{field: value})
      {:ok, %Visit{}}

      iex> create_visit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_visit(attrs \\ %{}) do
    %Visit{}
    |> Visit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a visit.

  ## Examples

      iex> update_visit(visit, %{field: new_value})
      {:ok, %Visit{}}

      iex> update_visit(visit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_visit(%Visit{} = visit, attrs) do
    visit
    |> Visit.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a visit.

  ## Examples

      iex> delete_visit(visit)
      {:ok, %Visit{}}

      iex> delete_visit(visit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_visit(%Visit{} = visit) do
    Repo.delete(visit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking visit changes.

  ## Examples

      iex> change_visit(visit)
      %Ecto.Changeset{data: %Visit{}}

  """
  def change_visit(%Visit{} = visit, attrs \\ %{}) do
    Visit.changeset(visit, attrs)
  end

  @doc """
  Accepts a :pending visit which adds a pal and updates status to :accepted.

  ## Examples

      iex> update_visit(visit, %{status: :pending})
      {:ok, %Visit{}}

      iex> update_visit(visit, %{status: fulfilled})
      {:error, %Ecto.Changeset{}}

  """
  def accept_visit(%Visit{} = visit, pal) do
    visit
    |> Visit.status_changeset(%{pal: pal, status: :accepted})
    |> Repo.update()
  end

  @doc """
  Fulfills an :accepted visit which debits the member's balance, credits the pal's balance, and updates the visit status to :fulfilled.

  ## Examples

      iex> fulfill_visit(%Visit{status: :accepted})
      {:ok, %Visit{}}

      iex> fulfill_visit(%Visit{status: :pending})
      {:error, %Ecto.Changeset{}}

  """
  def fulfill_visit(%Visit{} = visit) do
    visit =
      visit
      |> Repo.preload(:member_user)
      |> Repo.preload(:pal_user)

    member_user =
      case visit.member_user do
        nil -> %User{}
        _ -> visit.member_user
      end

    pal_user =
      case visit.pal_user do
        nil -> %User{}
        _ -> visit.pal_user
      end

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :member,
      User.balance_changeset(member_user, %{
        balance: Helpers.get_debited_member_balance(Map.get(member_user, :balance), visit.minutes)
      })
    )
    |> Ecto.Multi.update(
      :pal,
      User.balance_changeset(pal_user, %{
        balance: Helpers.get_credited_pal_balance(Map.get(pal_user, :balance), visit.minutes)
      })
    )
    |> Ecto.Multi.update(:visit, Visit.status_changeset(visit, %{status: :fulfilled}))
    |> Repo.transaction()
    |> case do
      {:ok, %{visit: visit}} -> {:ok, visit}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end
end
