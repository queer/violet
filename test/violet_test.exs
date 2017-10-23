defmodule VioletTest do
  use ExUnit.Case
  doctest Violet

  test "checks for errors correctly" do
    assert Violet.is_error?(%{"errorCode": "100"}) == true
    assert Violet.is_error?(%{}) == false
  end
end
