defmodule ExW3.DummyRPC do
  @moduledoc "Dummy Json RPC Mock module for testing calls"

  def eth_call(_data), do: mock()
  def eth_send(_data), do: mock()

  def mock_response(resp), do: Application.put_env(:exw3, :dummy_rpc_resp, resp)
  def mock, do: Application.fetch_env!(:exw3, :dummy_rpc_resp)
end
