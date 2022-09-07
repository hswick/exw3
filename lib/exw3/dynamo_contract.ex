defmodule ExW3.DynamoContract do
  @moduledoc """
  Dynamically creates modules for ABIs at compile time.
  """

  @eth_module Application.compile_env(:exw3, :rpc_client, ExW3.Rpc)

  @doc "Gaurd for validating the response for eth_call"
  defguard valid_result(bin) when byte_size(bin) > 2

  @doc """
  Generate module for a given abi. The ABI can either be a json file path
  or a map.
  """
  @spec generate_module(module(), binary() | map()) :: {:module, module(), binary(), term()}
  def generate_module(module_name, abi) when is_list(abi) do
    functions =
      abi
      |> ABI.parse_specification()
      |> Enum.reject(&is_nil(&1.function))
      |> Enum.map(&generate_method(&1, module_name))

    Module.create(
      module_name,
      [generate_delegates() | functions],
      Macro.Env.location(__ENV__)
    )
  end

  def generate_module(module_name, file_name) when is_binary(file_name) do
    with {:ok, abi_bin} <- File.read(file_name),
         {:ok, abi} <- Jason.decode(abi_bin) do
      generate_module(module_name, abi)
    end
  end

  def generate_module(module_name, %{"abi" => abi}),
    do: generate_module(module_name, abi)

  @doc """
  Makes an eth_call to with the given data and overrides, Than parses
  the response using the selector in the params

  ## Examples

      iex> ERC20.total_supply() |> DynamoContract.call(to: "0xa0b...ef6")
      {:ok, [100000000000000]}
  """
  def call(%{data: _, selector: selector} = params, opts_and_overrides \\ []) do
    {block, overrides} = Keyword.pop(opts_and_overrides, :block, "latest")

    params =
      overrides
      |> Enum.into(params)
      |> Map.drop([:selector])

    with {:ok, resp} when valid_result(resp) <- unquote(@eth_module).eth_call([params, block]),
         {:ok, resp_bin} <- decode16(resp) do
      {:ok, ABI.decode(selector, resp_bin, :output)}
    else
      {:ok, "0x"} ->
        {:error, :unknown}

      {:error, cause} ->
        {:error, cause}
    end
  end

  @doc """
  Makes an eth_send to with the given data and overrides, Then returns the
  transaction binary.

  ## Examples

      iex> ERC20.transfer("0xff0...ea2", 1000) |> DynamoContract.send(to: "0xa0b...ef6")
      {:ok, transaction_bin}
  """
  def send(%{data: _} = params, overrides \\ []) do
    params =
      overrides
      |> Enum.into(params)
      |> Map.drop([:selector])

    with {:ok, resp} when valid_result(resp) <- unquote(@eth_module).eth_call([params]),
         {:ok, tx} <- unquote(@eth_module).eth_send([params]) do
      {:ok, tx}
    else
      {:ok, "0x"} ->
        {:error, :unknown}

      {:error, cause} ->
        {:error, cause}
    end
  end

  @doc false
  @spec encode16(binary()) :: String.t()
  def encode16(bin), do: "0x" <> Base.encode16(bin, case: :lower)

  @spec encode16(String.t()) :: {:ok, binary}
  def decode16(<<"0x", encoded::binary>>), do: decode16(encoded)
  def decode16(encoded) when rem(byte_size(encoded), 2) == 1, do: decode16("0" <> encoded)
  def decode16(encoded), do: Base.decode16(encoded, case: :mixed)

  @spec generate_method(ABI.FunctionSelector.t(), atom()) :: any()
  defp generate_method(selector, mod) do
    name =
      selector.function
      |> Macro.underscore()
      |> String.to_atom()

    func_args =
      selector.input_names
      |> Enum.count()
      |> Macro.generate_arguments(mod)

    quote do
      def unquote(name)(unquote_splicing(func_args), opts \\ []) do
        action_data =
          unquote(Macro.escape(selector))
          |> ABI.encode([unquote_splicing(func_args)])
          |> then(fn data ->
            case Keyword.get(opts, :data_as, :hex) do
              :binary -> data
              :hex -> ExW3.DynamoContract.encode16(data)
            end
          end)

        %{
          data: action_data,
          selector: unquote(Macro.escape(selector))
        }
      end
    end
  end

  @spec generate_delegates() :: any()
  defp generate_delegates do
    quote do
      defdelegate call(params, overrides \\ []), to: ExW3.DynamoContract
      defdelegate send(params, overrides \\ []), to: ExW3.DynamoContract
    end
  end
end
