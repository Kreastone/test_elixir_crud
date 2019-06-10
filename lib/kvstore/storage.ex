defmodule Storage do
  @moduledoc """
  Storage
  Module contains CRUD API
  """

  use GenServer
  alias :mnesia, as: Mnesia
  @mytable :kv
  @attributes [
    :key,              # Uniq Key
    :value,            # String
    :ttl               # Integer
  ]

  # Старт генсервера
  def start_link(_state \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Инициализация хранилища
  def init([]) do
    with create_schema <- Mnesia.create_schema([node()]),
      true <- (create_schema == :ok) || (create_schema == {:error, {node(), {:already_exists, node()}}}),
      :ok <- Mnesia.start(),
      create_table <- Mnesia.create_table(@mytable, [disc_copies: [node()], attributes: @attributes]),
      true <- (create_table == {:atomic, :ok}) || (create_table == {:aborted, {:already_exists, @mytable}})
    do
      # Запуск TTL таймера
      :timer.apply_interval(1000, __MODULE__, :timer_ttl,  [])
      {:ok, []}
    else
      _ ->
        {:stop, "database start error"}
    end
  end

  # TTL Timer
  def timer_ttl, do: Mnesia.transaction(fn ->
    Mnesia.foldl(fn(record, _acc) ->
      handle_ttl(record)
    end, [], @mytable)
  end)
  defp handle_ttl({@mytable, key, _value, 0}), do: Mnesia.delete({@mytable, key})
  defp handle_ttl({@mytable, key, value, ttl}) when is_integer(ttl), do: Mnesia.write({@mytable, key, value, ttl-1})
  defp handle_ttl({@mytable, key, _value, _ttl}), do: Mnesia.delete({@mytable, key})

  # Read
  def handle_call([:read, key], _from, state)
    do
      read = fn ->
        Mnesia.read({@mytable, key})
      end
      case Mnesia.transaction(read) do
        {:atomic, record} -> {:reply, record, state}
        _ ->  {:reply, :error, state}
      end
    end
  # Create
  # Update
  def handle_call([:update, key, value, ttl], _from, state)
    do
      update = fn ->
        Mnesia.write({@mytable, key, value, ttl})
      end
      case Mnesia.transaction(update) do
        {:atomic, :ok} -> {:reply, "ok", state}
        _ ->  {:reply, "error", state}
      end
    end

  # Delete
  def handle_call([:delete, key], _from, state)
    do
      delete = fn ->
        Mnesia.delete({@mytable, key})
      end
      case Mnesia.transaction(delete) do
        {:atomic, _} -> {:reply, "ok", state}
        _ ->  {:reply, "error", state}
      end
    end
  # Get table
  def handle_call([:get_table], _from, state)
    do
      get_table = fn ->
        Mnesia.foldl(fn({@mytable, key, value, ttl}, acc) ->
          [[key, value, ttl]] ++ acc
        end, [], @mytable)
      end
      case Mnesia.transaction(get_table) do
        {:atomic, table} -> {:reply, table, state}
        _ ->  {:reply, [], state}
      end
    end

  ### =====================
  ### Клиентский API
  ### =====================
  @doc """
  Create entry

  ## Parameters

    - key: Term
    - value: Term
    - ttl: Integer

    return "ok" | "error"

  ## Examples

      iex> Storage.create("key1", "value1", 100)
      "ok"

      iex> Storage.create("key2", "value2", 100)
      "ok"

  """
  @spec create(key :: term(), value :: term(), ttl :: integer()) :: String.t()
  def create(key, value, ttl) when is_integer(ttl) and ttl > 0, do: GenServer.call(__MODULE__, [:update, key, value, ttl])
  def create(_key, _value, _ttl), do: "error"
  @doc """
  Read entry

  ## Parameters

    - key: Term

    return :error | {:kv, key :: term(), value :: term(), ttl :: integer()}

  """
  @spec read(key :: term()) :: :error | term()
  def read(key), do: GenServer.call(__MODULE__, [:read, key])
  @doc """
  Update entry

  ## Parameters

    - key: Term
    - value: Term
    - ttl: Integer

    return "ok" | "error"

  """
  @spec update(key :: term(), value :: term(), ttl :: integer()) :: String.t()
  def update(key, value, ttl) when is_integer(ttl) and ttl > 0, do: GenServer.call(__MODULE__, [:update, key, value, ttl])
  def update(_key, _value, _ttl), do: "error"
  @doc """
  Delete entry

  ## Parameters

    - key: Term

    return "ok" | "error"

  """
  @spec delete(key :: term()) :: String.t()
  def delete(key), do: GenServer.call(__MODULE__, [:delete, key])
   @doc """
  Get all entries

  ## Parameters

   return [] | [ list[key :: term(), value :: term(), ttl :: integer()] 

  """
  @spec get_table() :: [list(term())]
  def get_table(), do: GenServer.call(__MODULE__, [:get_table])

  ### Debug
  def show do
    f_show = fn ->
      Mnesia.foldl(fn(record, _acc) ->
        IO.inspect record
        []
      end, [], @mytable)
    end
    Mnesia.transaction(f_show)
  end
end
