defmodule HomeVisitService.ActivityTest do
  use HomeVisitService.DataCase

  alias HomeVisitService.Activity

  describe "visits" do
    alias HomeVisitService.Activity.Visit
    alias HomeVisitService.Accounts

    import HomeVisitService.{ActivityFixtures, AccountsFixtures}

    @invalid_attrs %{date: nil, minutes: nil, tasks: nil}

    test "list_pending_visits/0 returns all pending visits" do
      visit = visit_fixture()
      [expected] = Activity.list_pending_visits()
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
    end

    test "list_visits_by_member/1 returns all visits for the given member" do
      visit = visit_fixture()
      [expected] = Activity.list_visits_by_member(visit.member)
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
    end

    test "get_requested_visit_minutes/1 returns requested visit minutes for the given member" do
      visit = visit_fixture(%{minutes: 12})
      assert 12 == Activity.get_requested_visit_minutes(visit.member)
    end

    test "list_visits_by_pal/1 returns all visits for the given pal" do
      visit = accepted_visit_fixture()
      [expected] = Activity.list_visits_by_pal(visit.pal)
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
    end

    test "get_visit!/1 returns the visit with given id" do
      visit = visit_fixture()
      expected = Activity.get_visit!(visit.id)
      assert visit.id == expected.id
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
    end

    test "create_visit/1 with valid data creates a visit" do
      d = get_test_visit_date(1)

      valid_attrs = %{
        date: d,
        minutes: 15,
        tasks: "some tasks",
        member: user_fixture().id
      }

      {:ok, visit} = Activity.create_visit(valid_attrs)
      assert visit.date == d
      assert visit.minutes == 15
      assert visit.tasks == "some tasks"
      assert visit.status == :pending
    end

    test "create_visit/1 with insufficient balance returns error changeset" do
      valid_attrs = %{
        date: get_test_visit_date(1),
        minutes: 42,
        tasks: "some tasks",
        member: user_fixture().id
      }

      assert {:error, %Ecto.Changeset{}} = Activity.create_visit(valid_attrs)
    end

    test "create_visit/1 with invalid date returns error changeset" do
      valid_attrs = %{
        date: get_test_visit_date(-1),
        minutes: 15,
        tasks: "some tasks",
        member: user_fixture().id
      }

      assert {:error, %Ecto.Changeset{}} = Activity.create_visit(valid_attrs)
    end

    test "create_visit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Activity.create_visit(@invalid_attrs)
    end

    test "update_visit/2 with valid data updates the visit" do
      visit = visit_fixture()
      d = get_test_visit_date(1)

      update_attrs = %{
        date: d,
        minutes: 15,
        tasks: "some updated tasks",
        member: user_fixture().id
      }

      assert {:ok, %Visit{} = visit} = Activity.update_visit(visit, update_attrs)
      assert visit.date == d
      assert visit.minutes == 15
      assert visit.tasks == "some updated tasks"
    end

    test "update_visit/2 with insufficient balance returns error changeset" do
      visit = visit_fixture()

      update_attrs = %{
        date: get_test_visit_date(1),
        minutes: 70,
        tasks: "some updated tasks",
        member: user_fixture().id
      }

      assert {:error, %Ecto.Changeset{}} = Activity.update_visit(visit, update_attrs)
    end

    test "update_visit/2 with invalid data returns error changeset" do
      visit = visit_fixture()
      assert {:error, %Ecto.Changeset{}} = Activity.update_visit(visit, @invalid_attrs)
      expected = Activity.get_visit!(visit.id)
      assert visit.id == expected.id
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
    end

    test "delete_visit/1 deletes the visit" do
      visit = visit_fixture()
      assert {:ok, %Visit{}} = Activity.delete_visit(visit)
      assert_raise Ecto.NoResultsError, fn -> Activity.get_visit!(visit.id) end
    end

    test "change_visit/1 returns a visit changeset" do
      visit = visit_fixture()
      assert %Ecto.Changeset{} = Activity.change_visit(visit)
    end

    test "accept_visit/2 with valid data updates the visit" do
      visit = visit_fixture()
      pal = user_fixture()
      {:ok, expected} = Activity.accept_visit(visit, pal.id)
      assert visit.id == expected.id
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
      assert pal.id == expected.pal
      assert :accepted == expected.status
    end

    test "accept_visit/2 when pal is member returns error changeset" do
      visit = visit_fixture()
      assert {:error, %Ecto.Changeset{}} = Activity.accept_visit(visit, visit.member)
      expected = Activity.get_visit!(visit.id)
      assert visit.id == expected.id
      assert visit.member == expected.member
      assert is_nil(expected.pal)
      assert :pending == expected.status
    end

    test "accept_visit/2 when visit is fulfilled returns error changeset" do
      visit = fulfilled_visit_fixture()
      assert {:error, %Ecto.Changeset{}} = Activity.accept_visit(visit, user_fixture().id)
      expected = Activity.get_visit!(visit.id)
      assert visit.id == expected.id
      assert :fulfilled == expected.status
    end

    test "fulfill_visit/2 with valid data updates the visit and updates the member and pal balances" do
      visit = accepted_visit_fixture()
      {:ok, expected} = Activity.fulfill_visit(visit)
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
      assert visit.pal == expected.pal
      assert :fulfilled == expected.status
      member = Accounts.get_user!(visit.member)
      pal = Accounts.get_user!(visit.pal)
      assert 20 == member.balance
      assert 38 == pal.balance
    end

    test "fulfill_visit/2 when visit is pending returns error changeset" do
      visit = visit_fixture()
      assert {:error, %Ecto.Changeset{}} = Activity.fulfill_visit(visit)
      expected = Activity.get_visit!(visit.id)
      assert visit.date == expected.date
      assert visit.minutes == expected.minutes
      assert visit.tasks == expected.tasks
      assert visit.member == expected.member
      assert :pending == expected.status
      member = Accounts.get_user!(visit.member)
      assert 30 == member.balance
    end
  end
end
