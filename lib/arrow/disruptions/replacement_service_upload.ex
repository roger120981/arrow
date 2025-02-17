defmodule Arrow.Disruptions.ReplacementServiceUpload do
  @moduledoc "functions for extracting shuttle replacement services from xlsx uploads"
  alias Arrow.Disruptions.ReplacementServiceUpload.{
    FirstTrip,
    LastTrip,
    Runtimes
  }

  @weekday_tab_name "WKDY headways and runtimes"
  @saturday_tab_name "SAT headways and runtimes"
  @sunday_tab_name "SUN headways and runtimes"

  @headers_regex [
    ~r/Start time/,
    ~r/End time/,
    ~r/Headway/,
    ~r/Running time\s\(Direction 0,/,
    ~r/Running time\s\(Direction 1,/
  ]

  @type tab_name :: String.t()
  @type row_index :: integer()
  @type ok_or_error :: {:ok, String.t() | number()} | {:error, String.t()}
  @type parsed_row :: %{required(:atom) => ok_or_error()}
  @type sheet_errors :: {:error, {row_index, parsed_row()}}
  @type sheet_data :: Runtimes.t() | FirstTrip.t() | LastTrip.t()
  @type error_tab :: {tab_name(), list(sheet_errors())}
  @type valid_tab :: {tab_name(), list(sheet_data())}

  @spec extract_data_from_upload(%{:path => binary(), optional(any()) => any()}) ::
          {:ok, {:error, list(String.t())} | {:ok, list(valid_tab())}}
  @doc """
  Parses a shuttle replacement service xlsx worksheet and returns a list of data
  """
  def extract_data_from_upload(%{path: xlsx_path}) do
    with tids when is_list(tids) <- Xlsxir.multi_extract(xlsx_path),
         {:ok, tab_map} <- get_xlsx_tab_tids(tids),
         {:ok, data} <- parse_tabs(tab_map) do
      {:ok, {:ok, data}}
    else
      {:error, error} -> {:ok, {:error, error |> Enum.map(&error_to_error_message/1)}}
    end
  end

  @spec error_to_error_message(error_tab()) :: list(String.t())
  def error_to_error_message({tab_name, errors}) when is_list(errors) do
    ["#{tab_name}" | errors |> Enum.map(&error_to_error_message/1)]
  end

  def error_to_error_message({idx, {:error, row_data}}) when is_list(row_data) do
    row_errors = Enum.into(row_data, %{}) |> Enum.map(fn {k, v} -> "#{error_type(k)}: #{v}" end)
    "Row #{idx}, #{row_errors}"
  end

  def error_to_error_message({idx, {:error, row_error}}) do
    "Row #{idx}, #{row_error}"
  end

  def error_to_error_message(error) do
    error
  end

  def error_type(:start_time), do: "Start Time"
  def error_type(:end_time), do: "End Time"
  def error_type(:headway), do: "Headway"
  def error_type(:running_time_0), do: "Running Time"
  def error_type(:running_time_1), do: "Running Time"
  def error_type(:first_trip_0), do: "First Trip"
  def error_type(:first_trip_1), do: "First Trip"
  def error_type(:last_trip_0), do: "Last Trip"
  def error_type(:last_trip_1), do: "Last Trip"
  def error_type(error), do: error

  @spec get_xlsx_tab_tids(any()) :: {:error, list(String.t())} | {:ok, map()}
  def get_xlsx_tab_tids(tab_tids) do
    all_tabs = [@weekday_tab_name, @saturday_tab_name, @sunday_tab_name]

    tab_map =
      Enum.reduce(tab_tids, %{}, fn {:ok, tid}, acc ->
        name = Xlsxir.get_info(tid, :name)

        if name in all_tabs do
          Map.put(acc, name, tid)
        else
          Xlsxir.close(tid)
          acc
        end
      end)

    if Enum.empty?(Map.keys(tab_map)) do
      {:error, ["Missing tab(s), none found for: #{Enum.join(all_tabs, ", ")}"]}
    else
      {:ok, tab_map}
    end
  end

  @spec get_tab(atom() | :ets.tid()) :: list()
  def get_tab(tab_id) do
    tab_id
    |> Xlsxir.get_list()
    # Cells that have been touched but are empty can return nil
    |> Enum.reject(fn list -> Enum.all?(list, &is_nil/1) end)
    |> tap(fn _ -> Xlsxir.close(tab_id) end)
  end

  @spec parse_tabs(any()) :: {:error, list(error_tab())} | {:ok, list(valid_tab())}
  def parse_tabs(tab_map) do
    tab_map
    |> Enum.map(&parse_tab/1)
    |> Enum.split_with(&(elem(&1, 0) == :ok))
    |> case do
      {rows, []} -> {:ok, rows |> Enum.map(&elem(&1, 1))}
      {_, errors} -> {:error, errors |> Enum.map(&elem(&1, 1))}
    end
  end

  @type parsed_tab ::
          {:ok, valid_tab()} | {:error, error_tab()}

  @spec parse_tab({String.t(), atom() | :ets.tid()}) ::
          parsed_tab()
  def parse_tab({tab_name, tab_id}) do
    tab = get_tab(tab_id)

    with {:ok, _headers} <- validate_headers(tab),
         {:ok, sheet_data} <- parse_sheet(tab),
         {:ok, _sheet_data_with_first_last} <- ensure_first_last(sheet_data) do
      {:ok, {tab_name, sheet_data}}
    else
      {:error, error} ->
        {:error, {tab_name, error}}
    end
  end

  defp header_to_string(header_regex) do
    header_regex
    |> Regex.source()
    |> String.replace("\\s\\(", " (")
    |> String.replace("0,", "0, ...)")
    |> String.replace("1,", "1, ...)")
  end

  @spec validate_headers(nonempty_maybe_improper_list()) ::
          {:error, list(String.t())} | {:ok, list()}
  def validate_headers([headers | _]) do
    headers
    |> Enum.zip(@headers_regex)
    |> Enum.map(&{&1, String.match?(elem(&1, 0), elem(&1, 1))})
    |> Enum.split_with(&elem(&1, 1))
    |> case do
      {headers, []} ->
        {:ok, headers |> Enum.map(fn {key, _val} -> elem(key, 0) end)}

      {_, missing} ->
        headers_str = @headers_regex |> Enum.map_join(", ", &header_to_string/1)

        missing_header =
          missing
          |> Enum.map(fn {key, _val} -> elem(key, 1) end)
          |> Enum.map(&header_to_string/1)
          |> List.first()

        {:error,
         ["Invalid header: column not found for #{missing_header}. expected: #{headers_str}"]}
    end
  end

  @spec ensure_first_last(list) :: {:error, list(String.t())} | {:ok, list()}
  def ensure_first_last(runtimes) do
    trips =
      runtimes
      |> Enum.map(&has_first_last_trip_times?/1)
      |> Enum.filter(&elem(&1, 0))
      |> Enum.map(&elem(&1, 1))

    first? = Enum.member?(trips, :first)
    last? = Enum.member?(trips, :last)

    if first? && last? do
      {:ok, runtimes}
    else
      values = [{first?, "First"}, {last?, "Last"}] |> Enum.reject(&elem(&1, 0))

      {:error, ["Missing row for #{values |> Enum.map_join(" and ", &elem(&1, 1))} trip times"]}
    end
  end

  @spec has_first_last_trip_times?(map) :: {false, :none} | {true, :first | :last}
  def has_first_last_trip_times?(%{first_trip_0: _, first_trip_1: _}) do
    {true, :first}
  end

  def has_first_last_trip_times?(%{last_trip_0: _, last_trip_1: _}) do
    {true, :last}
  end

  def has_first_last_trip_times?(_) do
    {false, :none}
  end

  @spec parse_sheet(nonempty_maybe_improper_list()) ::
          {:error, list(sheet_errors)} | {:ok, list(sheet_data)}
  def parse_sheet([_headers | data] = _tab) do
    data
    |> Enum.with_index(fn r, i -> {i + 2, r |> parse_row() |> validate_row()} end)
    |> Enum.split_with(fn {_i, r} -> elem(r, 0) == :ok end)
    |> case do
      {rows, []} -> {:ok, rows |> Enum.map(fn {_idx, {:ok, data}} -> Map.new(data) end)}
      {_, errors} -> {:error, errors}
    end
  end

  def validate_row({:error, error}) do
    {:error, error}
  end

  def validate_row(row) do
    row
    |> Enum.split_with(fn {_k, v} -> elem(v, 0) == :ok end)
    |> case do
      {rows, []} -> {:ok, rows |> Enum.map(fn {k, v} -> {k, elem(v, 1)} end)}
      {_, errors} -> {:error, errors |> Enum.map(fn {k, v} -> {k, elem(v, 1)} end)}
    end
  end

  @spec parse_row(list(any)) ::
          {:error, String.t()}
          | parsed_row()
  def parse_row([nil, nil, nil, "First " <> trip_0, "First " <> trip_1]) do
    %{
      first_trip_0: parse_time(trip_0),
      first_trip_1: parse_time(trip_1)
    }
  end

  def parse_row([nil, nil, nil, "Last " <> trip_0, "Last " <> trip_1]) do
    %{
      last_trip_0: parse_time(trip_0),
      last_trip_1: parse_time(trip_1)
    }
  end

  def parse_row([start_time, end_time, headway, running_time_0, running_time_1]) do
    %{
      start_time: parse_time(start_time),
      end_time: parse_time(end_time),
      headway: parse_number(headway),
      running_time_0: parse_number(running_time_0),
      running_time_1: parse_number(running_time_1)
    }
  end

  def parse_row(invalid_row) do
    {:error, "malformed row: #{inspect(invalid_row)}"}
  end

  @spec parse_time(binary()) :: {:error, binary()} | {:ok, String.t()}
  def parse_time(time_string) do
    with {:ok, truncated} <- truncate_seconds(time_string),
         padded <- pad_leading(truncated),
         [hr, min] <- to_time_int_list(padded),
         {:ok, _valid} <- validate_time_format([hr, min]) do
      {:ok, padded}
    else
      {:error, _time} -> {:error, "invalid time: #{time_string}"}
    end
  end

  def truncate_seconds(time_string) do
    case String.split(time_string, ":") do
      [_hr, _min, _sec] -> {:ok, String.split(time_string, ":") |> Enum.take(2) |> Enum.join(":")}
      [_hr, _min] -> {:ok, time_string}
      _ -> {:error, time_string}
    end
  end

  def pad_leading(time_string) do
    case String.length(time_string) do
      4 -> String.pad_leading(time_string, 5, "0")
      _ -> time_string
    end
  end

  def to_time_int_list(time_string) do
    String.split(time_string, ":") |> Enum.map(&String.to_integer/1) |> Enum.take(2)
  end

  @spec validate_time_format(list) :: {:error, list()} | {:ok, list()}
  def validate_time_format([hr, min]) when hr < 29 and min in 0..59 do
    {:ok, [hr, min]}
  end

  def validate_time_format(invalid_format) do
    {:error, invalid_format}
  end

  @spec parse_number(any()) :: {:error, any()} | {:ok, number()}
  def parse_number(value) do
    case is_number(value) do
      true -> {:ok, value}
      false -> {:error, value}
    end
  end
end

defmodule(Arrow.Disruptions.ReplacementServiceUpload.FirstTrip) do
  @moduledoc "struct to represent parsed first trip row"
  defstruct first_trip_0: nil, first_trip_1: nil

  @type t :: %__MODULE__{
          first_trip_0: String.t(),
          first_trip_1: String.t()
        }
end

defmodule(Arrow.Disruptions.ReplacementServiceUpload.LastTrip) do
  @moduledoc "struct to represent parsed last trip row"
  defstruct last_trip_0: nil, last_trip_1: nil

  @type t :: %__MODULE__{
          last_trip_0: String.t(),
          last_trip_1: String.t()
        }
end

defmodule(Arrow.Disruptions.ReplacementServiceUpload.Runtimes) do
  @moduledoc "struct to represent parsed runtimes row"
  defstruct start_time: nil,
            end_time: nil,
            headway: nil,
            running_time_0: nil,
            running_time_1: nil

  @type t :: %__MODULE__{
          start_time: String.t(),
          end_time: String.t(),
          headway: number(),
          running_time_0: number(),
          running_time_1: number()
        }
end
