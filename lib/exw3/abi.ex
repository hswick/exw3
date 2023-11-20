defmodule ExW3.Abi do
  @doc "Decodes event based on given data and provided signature"
  @spec decode_event(binary(), binary()) :: any()
  def decode_event(data, signature) do
    formatted_data =
      data
      |> String.slice(2..-1)
      |> Base.decode16!(case: :lower)

    fs = ABI.FunctionSelector.decode(signature)

    ABI.TypeDecoder.decode(formatted_data, fs)
  end

  @doc "Loads the abi at the file path and reformats it to a map"
  @spec load_abi(binary()) :: list() | {:error, atom()}
  def load_abi(file_path) do
    with {:ok, cwd} <- File.cwd(),
         {:ok, abi} <- File.read(Path.join([cwd, file_path])) do
      reformat_abi(Jason.decode!(abi))
    end
  end

  @doc "Loads the bin ar the file path"
  @spec load_bin(binary()) :: binary()
  def load_bin(file_path) do
    with {:ok, cwd} <- File.cwd(),
         {:ok, bin} <- File.read(Path.join([cwd, file_path])) do
      bin
    end
  end

  @doc "Decodes data based on given type signature"
  @spec decode_data(binary(), binary()) :: any()
  def decode_data(types_signature, data) do
    {:ok, trim_data} = String.slice(data, 2..String.length(data)) |> Base.decode16(case: :lower)

    ABI.decode(types_signature, trim_data) |> List.first()
  end

  @doc "Decodes output based on specified functions return signature"
  @spec decode_output(map(), binary(), binary()) :: list()
  def decode_output(abi, name, output) do
    {:ok, trim_output} =
      String.slice(output, 2..String.length(output)) |> Base.decode16(case: :lower)

    output_types = Enum.map(abi[name]["outputs"], fn x -> x["type"] end)
    types_signature = Enum.join(["(", Enum.join(output_types, ","), ")"])
    output_signature = "#{name}(#{types_signature})"

    outputs =
      ABI.decode(output_signature, trim_output)
      |> List.first()
      |> Tuple.to_list()

    outputs
  end

  @doc "Returns the type signature of a given function"
  @spec types_signature(map(), binary()) :: binary()
  def types_signature(abi, name) do
    input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
    types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
    types_signature
  end

  @doc "Returns the 4 character method id based on the hash of the method signature"
  @spec method_signature(map(), binary()) :: binary()
  def method_signature(abi, name) do
    if abi[name] do
      input_signature = ExKeccak.hash_256("#{name}#{types_signature(abi, name)}")

      # Take first four bytes
      <<init::binary-size(4), _rest::binary>> = input_signature
      init
    else
      raise "#{name} method not found in the given abi"
    end
  end

  @doc "Encodes data into Ethereum hex string based on types signature"
  @spec encode_data(binary(), list()) :: binary()
  def encode_data(types_signature, data) do
    ABI.TypeEncoder.encode_raw(
      [List.to_tuple(data)],
      ABI.FunctionSelector.decode_raw(types_signature),
      :standard
    )
  end

  @doc "Encodes list of options and returns them as a map"
  @spec encode_options(map(), list()) :: map()
  def encode_options(options, keys) do
    keys
    |> Enum.filter(fn option ->
      Map.has_key?(options, option)
    end)
    |> Enum.map(fn option ->
      {option, encode_option(options[option])}
    end)
    |> Enum.into(%{})
  end

  @doc "Encodes options into Ethereum JSON RPC hex string"
  @spec encode_option(integer()) :: binary()
  def encode_option(0), do: "0x0"

  def encode_option(nil), do: nil

  def encode_option(value) do
    "0x" <>
      (value
       |> :binary.encode_unsigned()
       |> Base.encode16(case: :lower)
       |> String.trim_leading("0"))
  end

  @doc "Encodes data and appends it to the encoded method id"
  @spec encode_method_call(map(), binary(), list()) :: binary()
  def encode_method_call(abi, name, input) do
    encoded_method_call =
      method_signature(abi, name) <> encode_data(types_signature(abi, name), input)

    encoded_method_call |> Base.encode16(case: :lower)
  end

  @doc "Encodes input from a method call based on function signature"
  @spec encode_input(map(), binary(), list()) :: binary()
  def encode_input(abi, name, input) do
    if abi[name]["inputs"] do
      input_types = Enum.map(abi[name]["inputs"], fn x -> x["type"] end)
      types_signature = Enum.join(["(", Enum.join(input_types, ","), ")"])
      input_signature = ExKeccak.hash_256("#{name}#{types_signature}")

      # Take first four bytes
      <<init::binary-size(4), _rest::binary>> = input_signature

      encoded_input =
        init <>
          ABI.TypeEncoder.encode_raw(
            [List.to_tuple(input)],
            ABI.FunctionSelector.decode_raw(types_signature),
            :standard
          )

      encoded_input |> Base.encode16(case: :lower)
    else
      raise "#{name} method not found with the given abi"
    end
  end

  defp reformat_abi(abi) do
    abi
    |> Enum.map(&map_abi/1)
    |> Map.new()
  end

  defp map_abi(x) do
    case {x["name"], x["type"]} do
      {nil, "constructor"} -> {:constructor, x}
      {nil, "fallback"} -> {:fallback, x}
      {name, _} -> {name, x}
    end
  end
end
