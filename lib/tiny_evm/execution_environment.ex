defmodule TinyEVM.ExecutionEnvironment do
  @moduledoc """
  A simplified version of the Execution Environment
  represented by `I` in the Yellow Paper.
  """

  alias TinyEVM.{MachineCode}

  defstruct address: nil,
            origin: nil,
            gas_price: 0,
            data: <<>>,
            sender: nil,
            value: 0,
            machine_code: <<>>,
            block_header: nil,
            call_depth: nil,
            permission: false

  @typespec"""
  From the Yellow Paper...
  Note: address is represented here as a string. The full implementation
  will represent addresses as a...
  """
  @type t :: %__MODULE__{
          address: String.t(),
          origin: <<_::160>>,
          gas_price: non_neg_integer(),
          data: binary(),
          sender: <<_::160>>,
          value: non_neg_integer(),
          machine_code: MachineCode.t(),
          # not sure on this one
          block_header: binary(),
          permission: boolean()
        }
end
