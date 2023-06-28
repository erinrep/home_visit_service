defmodule HomeVisitService.Helpers do
  @moduledoc """
  Helper functions.
  """

  @doc """
  Returns a new balance minus the minutes debited.

  ## Examples

      iex> get_debited_member_balance(20, 15)
      5

      iex> get_credited_pal_balance("bananas", 15)
      nil

  """
  def get_debited_member_balance(balance, minutes)
      when is_number(balance) and is_number(minutes) do
    balance - minutes
  end

  def get_debited_member_balance(_balance, _minutes) do
    nil
  end

  @doc """
  Returns a new balance plus the minutes credited minus 15%

  ## Examples

      iex> get_credited_pal_balance(20, 15)
      12

      iex> get_credited_pal_balance("bananas", 15)
      nil

  """
  def get_credited_pal_balance(balance, minutes) when is_number(balance) and is_number(minutes) do
    floor(balance + (minutes - minutes * 0.15))
  end

  def get_credited_pal_balance(_balance, _minutes) do
    nil
  end

  @doc """
  Returns the current balance a user receives when registering an account
  This is hard coded right now but could be a value that is set by an admin action
  so it could be updated when there is a sign up promotion

  ## Examples

      iex> get_registration_balance()
      30

  """
  def get_registration_balance() do
    30
  end
end
