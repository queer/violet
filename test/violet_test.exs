defmodule VioletTest do
  use ExUnit.Case
  doctest Violet

  test "that violet checks for errors correctly" do
    assert Violet.is_error?(%{"errorCode": "100"})
    assert Violet.is_error?(%{
      "cause" => "/obviously_fake_key",
      "errorCode" => 100,
      "index" => 9015,
      "message" => "Key not found",
      })
    refute Violet.is_error?(%{})
  end
end
