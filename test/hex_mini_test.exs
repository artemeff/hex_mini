defmodule HexMiniTest do
  use ExUnit.Case
  doctest HexMini

  test "greets the world" do
    assert HexMini.hello() == :world
  end
end
