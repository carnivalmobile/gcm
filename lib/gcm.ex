defmodule GCM do
  @moduledoc """
  GCM push notifications to devices.

  ```
  iex> GCM.push("api_key", ["registration_id"], %{notification: %{ title: "Hello!"} })
  {:ok,
   %{body: "...",
     canonical_ids: [], failure: 0,
     headers: [{"Content-Type", "application/json; charset=UTF-8"},
      {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
     invalid_registration_ids: [], not_registered_ids: [], status_code: 200,
     success: 1}}
  ```
  """
  alias HTTPoison.Response

  @base_url "https://gcm-http.googleapis.com/gcm"

  @doc """
  Push a notification to a list of `registration_ids` or a single `registration_id`
  using the `api_key` as authorization.

  ```
      iex> GCM.push(api_key, ["registration_id1", "registration_id2"])
      {:ok,
       %{body: "...",
         canonical_ids: [], failure: 0,
         headers: [{"Content-Type", "application/json; charset=UTF-8"},
          {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
        invalid_registration_ids: [], not_registered_ids: [], status_code: 200,
        success: 2}}
  ```
  """
  @spec push(String.t, String.t | [String.t], Map.t | Keyword.t) :: { :ok, Map.t } | { :error, term }
  def push(api_key, registration_ids, options \\ %{})
  def push(api_key, registration_id, options) when is_binary(registration_id) do
    push(api_key, [registration_id], options)
  end
  def push(api_key, registration_ids, options) do
    body = case registration_ids do
      [id] -> %{ to: id }
      ids -> %{ registration_ids: ids }
    end
      |> Dict.merge(options)
      |> Poison.encode!

    case HTTPoison.post(@base_url <> "/send", body, headers(api_key)) do
      { :ok, response } -> build_response(registration_ids, response)
      error -> error
    end
  end

  defp build_response(registration_ids, %Response{ headers: headers, status_code: 200, body: body }) do
    response = body |> Poison.decode!
    results = build_results(response, registration_ids)
              |> Map.merge(%{ failure: response["failure"],
                              success: response["success"],
                              body: body, headers: headers,
                              status_code: 200 })
    { :ok, results }
  end
  defp build_response(_, %Response{ status_code: 400 }) do
    { :error, :bad_request }
  end
  defp build_response(_, %Response{ status_code: 401 }) do
    { :error, :unauthorized }
  end
  defp build_response(_, %Response{ status_code: 503 }) do
    { :error, :service_unavaiable }
  end
  defp build_response(_, %Response{ status_code: code }) when code in 500..599 do
    { :error, :server_error }
  end

  @empty_results %{ not_registered_ids: [], canonical_ids: [], invalid_registration_ids: [] }

  defp build_results(%{ "failure" => 0, "canonical_ids" => 0 }, _), do: @empty_results
  defp build_results(%{ "results" => results}, reg_ids) do
    response = @empty_results
    Enum.zip(reg_ids, results)
      |> Enum.reduce(response, fn({reg_id, result}, response) ->
        case result do
          %{ "error" => "NotRegistered" } ->
            update_in(response[:not_registered_ids], &([reg_id | &1]))
          %{ "error" => "InvalidRegistration" } ->
            update_in(response[:invalid_registration_ids], &([reg_id | &1]))
          %{ "registration_id" => new_reg_id } ->
            update = %{ old: reg_id, new: new_reg_id}
            update_in(response[:canonical_ids], &([update | &1]))
          _ -> response
        end
      end)
  end
  defp build_results(_, _), do: @empty_results

  defp headers(api_key) do
    [{ "Authorization", "key=#{api_key}" },
     { "Content-Type", "application/json" },
     { "Accept", "application/json"}]
  end
end
