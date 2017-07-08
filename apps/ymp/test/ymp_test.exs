defmodule YMPTest do
  use ExUnit.Case
  doctest YMP

  test "get_host" do
    assert YMP.get_host == "localhost:4001"
  end
end
