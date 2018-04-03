defmodule EXW3 do

  @moduledoc """
  Documentation for EXW3.
  """

  @doc """
  Hello world.

  ## Examples

      iex> EXW3.hello
      :world

  """
  def hello do
    :world
  end

  def accounts do
    case Ethereumex.HttpClient.eth_accounts do
      {:ok, accounts} -> accounts
      err -> err
    end
  end

  def reformat_abi abi do
    Map.new Enum.map(abi, fn x -> {x["name"], x} end)
  end

  def load_abi file_path do
    file = File.read Path.join(System.cwd, file_path)
    case file do
      {:ok, abi} -> reformat_abi Poison.Parser.parse! abi
      err -> err
    end
  end

  def encode abi, name, args do
    inputs = Enum.map abi[name]["inputs"], fn x -> x["type"] end
    fn_signature = Enum.join [name, "(", Enum.join(inputs, ","), ")"]
    ABI.encode(fn_signature, args)
  end
end
