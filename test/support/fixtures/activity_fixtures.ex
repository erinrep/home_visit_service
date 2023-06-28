defmodule HomeVisitService.ActivityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HomeVisitService.Activity` context.
  """

  import HomeVisitService.AccountsFixtures

  @doc """
  Generate a visit.
  """
  def visit_fixture(attrs \\ %{}) do
    {:ok, visit} =
      attrs
      |> Enum.into(%{
        date: get_test_visit_date(1),
        minutes: 10,
        tasks: "some tasks",
        member: user_fixture().id
      })
      |> HomeVisitService.Activity.create_visit()

    visit
  end

  @doc """
  Generate and accept a visit.
  """
  def accepted_visit_fixture(attrs \\ %{}) do
    visit = visit_fixture(attrs)
    {:ok, visit} = HomeVisitService.Activity.accept_visit(visit, user_fixture().id)

    visit
  end

  @doc """
  Generate, accept, and fulfill a visit.
  """
  def fulfilled_visit_fixture(attrs \\ %{}) do
    visit = accepted_visit_fixture(attrs)
    {:ok, visit} = HomeVisitService.Activity.fulfill_visit(visit)

    visit
  end

  @doc """
  Generate a valid test date for a visit adding the given days to today's date
  """
  def get_test_visit_date(days \\ 1) do
    DateTime.truncate(DateTime.add(DateTime.utc_now(), days, :day), :second)
  end
end
