defmodule TinyEVM.Operation.Metadata do
  @moduledoc """
  Defines the struct for the metadata associated with
  opcodes defined in Appendix H of the Yellow Paper.
  """

  defstruct value: nil,
            mnemonic: nil,
            function: nil,
            args: [],
            inputs: nil,
            outputs: nil,
            description: "",
            machine_code_offset: 0

  @type t :: %__MODULE__{
          value: integer(),
          mnemonic: atom(),
          function: atom(),
          args: [],
          inputs: non_neg_integer(),
          outputs: non_neg_integer(),
          description: String.t(),
          machine_code_offset: non_neg_integer() | nil
        }
end
