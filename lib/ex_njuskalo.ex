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
    |> Map.get("data")
    |> Enum.map(fn r ->
      %{
        label: r["attributes"]["label"],
        group_id: String.to_integer(r["id"])
      }
    end)
  end

  def get_resp(path) do
    api_url(path)
    |> HTTPoison.get!([
      {"authorization", get_token([{"grant_type", "client_credentials"}])},
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

  defp get_token(formdata) do
    api_url("token")
    |> HTTPoison.post!({:form, formdata}, [
      {
        "authorization",
        "Basic " <> Application.fetch_env!(:ex_njuskalo, :basic_auth_token)
      },
      {
        "user-agent",
        "Dalvik/2.1.0 (Linux; U; Android 10; SM-G950F Build/QQ3A.200805.001)"
      }
    ])
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("access_token")
    |> String.replace_prefix("", "Bearer ")
  end

  defp api_url(path) do
    "https://ia" <>
      "pi.nj" <>
      "uskal" <>
      "o.hr/c" <>
      "cap" <>
      "i/v2/" <> path
  end
end
