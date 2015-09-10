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
     not_registered_ids: [], status_code: 200, success: 1}}
  ```
  """
  alias HTTPoison.Response

  @base_url "https://android.googleapis.com/gcm"

  @doc """
  Push a notification to a list of `registration_ids` using the `api_key` as authorization

      iex> GCM.push(api_key, ["registration_id1", "registration_id2"])
      {:ok,
       %{body: "...",
         canonical_ids: [], failure: 0,
         headers: [{"Content-Type", "application/json; charset=UTF-8"},
          {"Vary", "Accept-Encoding"}, {"Transfer-Encoding", "chunked"}],
         not_registered_ids: [], status_code: 200, success: 2}}
  """
  @spec push(binary, [binary], map | [Keyword]) :: { :ok, map } | { :error, term }
  def push(api_key, registration_ids, options \\ %{}) do
    body = %{ registration_ids: registration_ids }
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

  defp build_results(%{ "failure" => 0, "canonical_ids" => 0 }, _) do
    %{ not_registered_ids: [], canonical_ids: [] }
  end
  defp build_results(%{ "results" => results}, reg_ids) do
    { not_reg_ids, canonical_ids } = Enum.zip(reg_ids, results)
      |> Enum.reduce({[], []},
        fn {reg_id, result}, {not_reg_ids, canonical_ids} ->
          case result do
            %{ "error" => "NotRegistered" } -> {[reg_id | not_reg_ids], canonical_ids}
            %{ "registration_id" => new_reg_id } -> {not_reg_ids, [%{ old: reg_id, new: new_reg_id} | canonical_ids]}
            _ -> {not_reg_ids, canonical_ids}
          end
        end
      )
    %{ not_registered_ids: not_reg_ids, canonical_ids: canonical_ids }
  end
  defp build_results(_, _), do: %{ not_registered_ids: [], canonical_ids: [] }

  defp headers(api_key) do
    [{ "Authorization", "key=#{api_key}" },
     { "Content-Type", "application/json" },
     { "Accept", "application/json"}]
  end
end
