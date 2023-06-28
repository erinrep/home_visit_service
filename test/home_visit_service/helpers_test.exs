defmodule HomeVisitService.HelpersTest do
  use HomeVisitService.DataCase

  alias HomeVisitService.Helpers

  describe "get_debited_member_balance/2" do
    test "returns updated balance when arguments are numbers" do
      assert Helpers.get_debited_member_balance(30, 10) == 20
    end

    test "returns nil when arguments are not numbers" do
      assert is_nil(Helpers.get_debited_member_balance("bananas", 10))
      assert is_nil(Helpers.get_debited_member_balance(20, "bananas"))
      assert is_nil(Helpers.get_debited_member_balance(nil, nil))
    end
  end

  describe "get_credited_pal_balance/2" do
    test "returns updated balance when arguments are numbers" do
      assert Helpers.get_credited_pal_balance(30, 10) == 38
    end

    test "returns nil when arguments are not numbers" do
      assert is_nil(Helpers.get_credited_pal_balance("bananas", 10))
      assert is_nil(Helpers.get_credited_pal_balance(20, "bananas"))
      assert is_nil(Helpers.get_credited_pal_balance(nil, nil))
    end
  end

  describe "get_registration_balance/0" do
    test "returns current registration balance" do
      assert Helpers.get_registration_balance() == 30
    end
  end
end
