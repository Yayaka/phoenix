defmodule AmorphosTest do
  use ExUnit.Case
  @information Application.get_env(:amorphos, :host_information)

  test "get_host" do
    assert Amorphos.get_host == "localhost:4001"
  end

  test "get_information" do
    assert Amorphos.get_host_information == @information
  end
end
