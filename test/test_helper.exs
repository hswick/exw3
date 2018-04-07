defmodule Log do
  def p input do
    input
    |> Kernel.inspect
    |> IO.puts
  end
end

ExUnit.start()