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

  @typedoc """
  From Yellow Paper:

    `I` is defined as:
      - `I_a`: The address of the account which owns the code that is executing.
               This implementation represents the address as a string where the full
               implementation stores addresses as 160-bit identifiers.
      - `I_o`: The sender address of the transaction that originated this transaction.
               This implementation doesn't support `CALL` or `CREATE` opcodes, so this
               is unused.
      - `I_p`: The price of gas in the transaction that originated this execution.
      - `I_d`: The byte array that is the input data to this execution.
      - `I_s`: The address of the account which caused the code to be executing.
      - `I_v`: The value, in Wei, pass to this account as part of the same procedure
               as execution.
      - `I_b`: The byte array that is the machine code to be executed.
      - `I_H`: The block header of the present block, skipped in this implementation.
      - `I_e`: The depth of the present message-call or contract creation. Skipped in
               this implementation.
      - `I_w`: The permission to make modifications to the state.
  """
  @type t :: %__MODULE__{
          address: String.t(),
          origin: <<_::160>>,
          gas_price: non_neg_integer(),
          data: binary(),
          sender: <<_::160>>,
          value: non_neg_integer(),
          machine_code: MachineCode.t(),
          # In a full implementaiton, block_header would be represnted by
          # a BockHeader struct, not a binary
          block_header: binary(),
          permission: boolean()
        }
end
