defmodule FaultTree.Analyzer.Probability do
  @moduledoc """
  Holds state when processing the probability across a fault tree. This is particularly useful
  for transfer gates when trying to determine the probability of their source node.
  """

  use GenServer
  require Logger

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    probability = Map.get(state, name)
    {:reply, probability, state}
  end

  @impl true
  def handle_call({:save, %FaultTree.Node{name: name, probability: probability}}, _from, state) do
    {:reply, :ok, Map.put_new(state, name, probability)}
  end

  @doc """
  Store the result of a probability calculation. Returns the node for chaining.
  """
  def save(node = %FaultTree.Node{}, pid) do
    :ok = GenServer.call(pid, {:save, node})
    node
  end

  @doc """
  Return the cached probability result for a given node.
  """
  def lookup(%FaultTree.Node{name: name}, pid) do
    GenServer.call(pid, {:lookup, name})
  end
end
