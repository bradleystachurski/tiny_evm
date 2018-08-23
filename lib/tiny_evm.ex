defmodule TinyEVM do
  @moduledoc"""
  A simplified version of the Ethereum Virtual Machine.
  """

  alias TinyEVM.{MachineState}

  @doc"""
  Due to the TinyEVM's _tinyness_, `execute` is a variant of the
  `Ξ` function, formally defined in section 9.4 of the Yellow Paper.

  The variation is due to the requirements of only the three following
  paramaters (as opposed to the full definition in the Yellow Paper).


  ## Parameters

    - `address`: The address any storage modifcations are applied to.
    - `gas`: Total gas units sent for this "transaction" (not actually
      a formal transaction, however a proxy for a transaction in the TinyEVM).
    - `code`: The binary of the EVM machine code (meant to represent the
      contract code that would normally be associated with the address).

  ## Returns

    - `g′`: The remaining gas after execution.
    - `σ′`: The resultantant state after execution (for the purposes of the
            TinyEVM, the world state is represented as a simple mapping
            between addresses and storage, as opposed to a Merkle Patricia Trie).

    Note: `Ξ` in the full EVM implementation will also return `A`, the accrued
          substate and `o`, the resultant output.

  ## Examples

    # Some pretty cool examples go here
  """
  #TODO: Might need to change the return map type. We'll find out
  @spec execute(String.t(), non_neg_integer(), binary()) :: {integer(), %{optional(<<_::160>>) => map()}}
  def execute(address, gas, code) do
    IO.inspect address, label: "address"
    IO.inspect gas, label: "gas"
    IO.inspect code, label: "code"
    {0, %{}}
  end
end
