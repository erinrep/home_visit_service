defmodule HomeVisitServiceWeb.VisitControllerTest do
  alias HomeVisitService.Activity.Visit
  alias HomeVisitService.Activity
  use HomeVisitServiceWeb.ConnCase

  import HomeVisitService.ActivityFixtures

  @create_attrs %{
    date: get_test_visit_date(1),
    minutes: 15,
    tasks: "some tasks"
  }
  @update_attrs %{
    date: get_test_visit_date(2),
    minutes: 20,
    tasks: "some updated tasks"
  }
  @invalid_attrs %{date: nil, minutes: nil, tasks: nil}

  defp create_visit(_) do
    visit = visit_fixture()
    %{visit: visit}
  end

  setup [:register_and_log_in_user, :create_visit]

  describe "index" do
    test "lists all visits", %{conn: conn} do
      conn = get(conn, ~p"/visits")
      assert html_response(conn, 200) =~ "Visits"
    end
  end

  describe "my visits" do
    test "lists all visits for the user", %{conn: conn} do
      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "My Visits"
    end
  end

  describe "new visit" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/visits/new")
      assert html_response(conn, 200) =~ "Request Visit"
    end
  end

  describe "create visit" do
    test "redirects to list when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/visits", visit: @create_attrs)

      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/visits")
      assert html_response(conn, 200) =~ @create_attrs.tasks
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/visits", visit: @invalid_attrs)
      assert html_response(conn, 200) =~ "Request Visit"
    end
  end

  describe "edit visit" do
    setup [:create_visit]

    test "renders form for editing chosen visit", %{conn: conn, visit: visit} do
      conn = get(conn, ~p"/visits/#{visit}/edit")
      assert html_response(conn, 200) =~ "Edit Visit"
    end
  end

  describe "update visit" do
    test "redirects when data is valid", %{conn: conn, visit: visit} do
      conn = log_in_user(conn, %{id: visit.member})
      conn = put(conn, ~p"/visits/#{visit}", visit: @update_attrs)
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "some updated tasks"
    end

    test "renders errors when data is invalid", %{conn: conn, visit: visit} do
      conn = log_in_user(conn, %{id: visit.member})
      conn = put(conn, ~p"/visits/#{visit}", visit: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Visit"
    end

    test "renders error if visit not found", %{conn: conn} do
      conn = put(conn, ~p"/visits/#{%Visit{id: 99}}", visit: @update_attrs)
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "Visit not found"
    end
  end

  describe "delete visit" do
    test "deletes chosen visit", %{conn: conn, visit: visit} do
      conn = log_in_user(conn, %{id: visit.member})
      conn = delete(conn, ~p"/visits/#{visit}")
      assert redirected_to(conn) == ~p"/my-visits"

      assert_raise Ecto.NoResultsError,
                   ~r/^expected at least one result/,
                   fn ->
                     Activity.get_visit!(visit.id)
                   end
    end

    test "renders error if visit doesn't belong to the user", %{conn: conn, visit: visit} do
      conn = delete(conn, ~p"/visits/#{visit}")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "forbidden"
    end
  end

  describe "accept visit" do
    test "displays success message when valid", %{conn: conn, visit: visit} do
      conn = post(conn, ~p"/visits/#{visit}/accept")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "accepted"
    end

    test "renders error if member tries to accept their own visit", %{conn: conn, visit: visit} do
      conn = log_in_user(conn, %{id: visit.member})
      conn = post(conn, ~p"/visits/#{visit}/accept")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "Could not accept visit"
    end

    test "renders error if visit not found", %{conn: conn} do
      conn = post(conn, ~p"/visits/#{%Visit{id: 99}}/accept")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "Visit not found"
    end
  end

  describe "fulfill visit" do
    test "displays success message when valid", %{conn: conn} do
      visit = accepted_visit_fixture()
      conn = log_in_user(conn, %{id: visit.member})
      conn = post(conn, ~p"/visits/#{visit}/fulfill")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "fulfilled"
    end

    test "renders error if non owner tries to fulfill", %{conn: conn, user: user} do
      visit = accepted_visit_fixture()
      conn = log_in_user(conn, user)
      conn = post(conn, ~p"/visits/#{visit}/fulfill")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "forbidden"
    end

    test "renders error if visit not accepted", %{conn: conn} do
      visit = visit_fixture()
      conn = log_in_user(conn, %{id: visit.member})
      conn = post(conn, ~p"/visits/#{visit}/fulfill")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "Could not fulfill visit"
    end

    test "renders error if visit not found", %{conn: conn} do
      conn = post(conn, ~p"/visits/#{%Visit{id: 99}}/fulfill")
      assert redirected_to(conn) == ~p"/my-visits"

      conn = get(conn, ~p"/my-visits")
      assert html_response(conn, 200) =~ "Visit not found"
    end
  end
end
