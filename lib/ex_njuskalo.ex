defmodule ExNjuskalo do
  @moduledoc """
  ExNjuskalo is unofficial elixir lib for accessing njuskalo.hr public data and managing njuskalo account.
  """

  @doc """
  Returns search results
  """
  def search_ads(query) do
  end

  @doc """
  Returns search suggestions
  """
  def search_suggestions(query) do
    qs =
      %{"filter[term]": query}
      |> URI.encode_query()

    get_resp("search-suggestions?" <> qs)
    |> IO.inspect()
    |> Map.get("data")
    |> Enum.map(fn r ->
      %{
        label: r["attributes"]["label"],
        group_id:
          r["id"]
          |> String.to_integer()
      }
    end)
  end

  def get_resp(path) do
    token =
      api_url("token")
      |> HTTPoison.post!({:form, [{"grant_type", "client_credentials"}]}, [
        {
          "authorization",
          "Basic bmp1c2thbG9fYW5kcm9pZF9tb2JpbGVfYXBwOmQxZTM1OGU2ZTNiNzA3MjgyY2RkMDZlOTE5ZjdlMDhj"
        },
        {
          "user-agent",
          "Dalvik/2.1.0 (Linux; U; Android 10; SM-G950F Build/QQ3A.200805.001)"
        }
      ])
      |> Map.get(:body)
      |> Jason.decode!()

    api_url(path)
    |> HTTPoison.get!([
      {"authorization", "#{token["token_type"]} #{token["access_token"]}"},
      {
        "version",
        "2.1"
      },
      {
        "user-agent",
        "Dalvik/2.1.0 (Linux; U; Android 10; SM-G950F Build/QQ3A.200805.001)"
      }
    ])
    |> Map.get(:body)
    |> Jason.decode!()
  end

  defp get_resp_with_auth(username, password, path) do
    :todo
  end

  defp api_url(path) do
    "https://iapi.njuskalo.hr/ccapi/v2/" <> path
  end
end
