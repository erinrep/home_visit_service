defmodule HomeVisitServiceWeb.VisitController do
  use HomeVisitServiceWeb, :controller

  alias HomeVisitService.Activity
  alias HomeVisitService.Activity.Visit

  def index(conn, _params) do
    visits = Activity.list_pending_visits()
    render(conn, :index, visits: visits)
  end

  @spec my_visits(Plug.Conn.t(), any) :: Plug.Conn.t()
  def my_visits(conn, _params) do
    member_visits = Activity.list_visits_by_member(conn.assigns.current_user.id)
    pal_visits = Activity.list_visits_by_pal(conn.assigns.current_user.id)
    pending_balance = Activity.get_requested_visit_minutes(conn.assigns.current_user.id)

    render(conn, :my_visits,
      member_visits: member_visits,
      pal_visits: pal_visits,
      pending_balance: pending_balance
    )
  end

  def new(conn, _params) do
    changeset = Activity.change_visit(%Visit{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"visit" => visit_params}) do
    visit_params_with_member = visit_params |> Map.put("member", conn.assigns.current_user.id)

    case Activity.create_visit(visit_params_with_member) do
      {:ok, _visit} ->
        conn
        |> put_flash(:info, "Visit requested successfully.")
        |> redirect(to: ~p"/my-visits")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    try do
      visit = Activity.get_visit!(id)
      changeset = Activity.change_visit(visit)
      render(conn, :edit, visit: visit, changeset: changeset)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Visit not found.")
        |> redirect(to: ~p"/my-visits")
    end
  end

  def update(conn, %{"id" => id, "visit" => visit_params}) do
    try do
      visit = Activity.get_visit!(id)

      if visit.member != conn.assigns.current_user.id do
        conn
        |> put_flash(:error, "forbidden")
        |> redirect(to: ~p"/my-visits")
      else
        case Activity.update_visit(visit, visit_params) do
          {:ok, _visit} ->
            conn
            |> put_flash(:info, "Visit updated successfully.")
            |> redirect(to: ~p"/my-visits")

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, :edit, visit: visit, changeset: changeset)
        end
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Visit not found.")
        |> redirect(to: ~p"/my-visits")
    end
  end

  def delete(conn, %{"id" => id}) do
    visit = Activity.get_visit!(id)

    if visit.member != conn.assigns.current_user.id do
      conn
      |> put_flash(:error, "forbidden")
      |> redirect(to: ~p"/my-visits")
    else
      {:ok, _visit} = Activity.delete_visit(visit)

      conn
      |> put_flash(:info, "Visit deleted successfully.")
      |> redirect(to: ~p"/my-visits")
    end
  end

  def accept(conn, %{"id" => id}) do
    try do
      visit = Activity.get_visit!(id)

      case Activity.accept_visit(visit, conn.assigns.current_user.id) do
        {:ok, _visit} ->
          conn
          |> put_flash(:info, "Visit accepted.")
          |> redirect(to: ~p"/my-visits")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Could not accept visit")
          |> redirect(to: ~p"/my-visits")
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Visit not found.")
        |> redirect(to: ~p"/my-visits")
    end
  end

  def fulfill(conn, %{"id" => id}) do
    try do
      visit = Activity.get_visit!(id)

      if visit.member != conn.assigns.current_user.id do
        conn
        |> put_flash(:error, "forbidden")
        |> redirect(to: ~p"/my-visits")
      else
        case Activity.fulfill_visit(visit) do
          {:ok, _visit} ->
            conn
            |> put_flash(:info, "Visit fulfilled.")
            |> redirect(to: ~p"/my-visits")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Could not fulfill visit")
            |> redirect(to: ~p"/my-visits")
        end
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_flash(:error, "Visit not found.")
        |> redirect(to: ~p"/my-visits")
    end
  end
end
