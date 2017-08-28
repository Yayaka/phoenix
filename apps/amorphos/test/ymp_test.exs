defmodule AmorphosTest do
  use ExUnit.Case
  doctest Amorphos

  test "get_host" do
    assert Amorphos.get_host == "localhost:4001"
  end
end
