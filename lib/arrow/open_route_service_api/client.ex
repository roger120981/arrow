defmodule Arrow.OpenRouteServiceAPI.Client do
  @behaviour Arrow.OpenRouteServiceAPI.Client
  @moduledoc """
  An HTTP Client that reaches out to Open Route Service
  Based on mbta/skate's implementation
  """

  alias Arrow.OpenRouteServiceAPI.DirectionsRequest

  @callback get_directions(DirectionsRequest.t()) :: {:ok, map()} | {:error, any()}

  @doc """
  Sends `request` to the OpenRouteService API and then sends the response through
  `parse_response/1` before returning it
  """
  @spec get_directions(DirectionsRequest.t()) :: {:ok, map()} | {:error, any()}
  def get_directions(request) do
    response =
      HTTPoison.post(
        directions_api(),
        Jason.encode!(request),
        headers(api_key())
      )

    parse_response(response)
  end

  @doc """
  Parses the HTTPoison response into something that's a little more HTTP-client agnostic.

  If the request was successful, it returns a tuple that includes the response parsed as JSON.

  ## Example
      iex> Arrow.OpenRouteServiceAPI.Client.parse_response(
      ...>   {
      ...>     :ok,
      ...>     %HTTPoison.Response{
      ...>       body: "{\\"data\\": \\"foobar\\"}",
      ...>       status_code: 200
      ...>     }
      ...>   }
      ...> )
      {:ok, %{"data" => "foobar"}}

  If the request was unsuccessful, then it returns an error indicating what went wrong.

  ## Examples
      iex> Arrow.OpenRouteServiceAPI.Client.parse_response(
      ...>   {
      ...>     :ok,
      ...>     %HTTPoison.Response{
      ...>       body: "{\\"error\\": \\"nope\\"}",
      ...>       status_code: 400
      ...>     }
      ...>   }
      ...> )
      {:error, "nope"}

      iex> Arrow.OpenRouteServiceAPI.Client.parse_response(
      ...>   {
      ...>     :error,
      ...>     %HTTPoison.Error{}
      ...>   }
      ...> )
      {:error, "unknown"}
  """
  @spec parse_response({:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}) ::
          {:ok, map()} | {:error, any()}
  def parse_response(response) do
    case response do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        Jason.decode(body, strings: :copy)

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:error, Jason.decode!(body)["error"]}

      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        {:error, Jason.decode!(body)["error"]}

      {:error, %HTTPoison.Error{}} ->
        {:error, "unknown"}
    end
  end

  defp directions_api do
    api_base_url()
    |> URI.merge(directions_path())
    |> URI.to_string()
  end

  defp api_base_url, do: Application.get_env(:arrow, Arrow.OpenRouteServiceAPI)[:api_base_url]

  defp directions_path,
    do: "v2/directions/driving-hgv/geojson"

  defp headers(nil) do
    headers()
  end

  defp headers(api_key) do
    [
      {"Authorization", api_key}
      | headers()
    ]
  end

  defp headers do
    [{"Content-Type", "application/json"}]
  end

  # For use with https://api.openrouteservice.org/, you can request an API key from their console
  defp api_key, do: Application.get_env(:arrow, Arrow.OpenRouteServiceAPI)[:api_key]
end
