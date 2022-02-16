defmodule ExNjuskalo do
  @moduledoc """
  ExNjuskalo is unofficial elixir lib for accessing njuskalo.hr public data and managing njuskalo account.
  """

  @doc """
  Returns search results

  Possible values for sort:

  - `relevance` (Relevantnost)
  - `old` (Najstariji)
  - `new` (Najnoviji)
  - `expensive` (S višom cijenom)
  - `cheap` (S nižom cijenom)
  """
  def search_ads(query), do: search_ads(query, nil, 1, "relevance")
  def search_ads(query, category_id), do: search_ads(query, category_id, 1, "relevance")
  def search_ads(query, category_id, page), do: search_ads(query, category_id, page, "relevance")

  def search_ads(query, category_id, page, sort) do
    qs =
      %{
        search: query,
        page: page,
        rootCategoryId: 0
      }
      |> maybe_put(category_id != nil, "categoryId[#{category_id}]", 1)
      |> maybe_put(sort != nil, "sort[#{sort}]", 1)

    get_list(qs)
  end

  @doc """
  Returns ads in category
  """
  def category(id), do: category(id, "relevance")

  def category(id, sort) do
    qs =
      %{
        rootCategoryId: id
      }
      |> maybe_put(sort != nil, "sort[#{sort}]", 1)

    get_list(qs)
  end

  @doc """
  Returns all categories
  """
  def categories do
    get_resp("mobile/page-category-hierarchy")
  end

  @doc """
  Returns car models
  """
  def car_models(), do: car_models(nil)

  def car_models(parent_id) do
    qs =
      %{}
      |> maybe_put("filter[parent]", parent_id)
      |> URI.encode_query()

    get_resp("form-data/choice/vehicle?" <> qs)
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
        category_id: String.to_integer(r["id"])
      }
    end)
  end

  defp get_list(qs) do
    qs =
      qs
      |> Map.put("include", "adListItems.image.variations")
      |> URI.encode_query()

    resp = get_resp("mobile/page-ad-list?" <> qs)

    if Map.has_key?(resp, "errors"), do: IO.inspect(resp)

    %{
      ads:
        resp["data"]["relationships"]["adListItems"]["data"]
        |> Enum.map(fn a ->
          ad =
            Enum.find(resp["included"], fn i ->
              i["id"] == a["id"] && i["type"] == "ad-list-item"
            end)

          image =
            Enum.find(resp["included"], fn i ->
              i["id"] == "#{ad["relationships"]["image"]["data"]["id"]}-variation-240x320"
            end)

          Map.put(ad, "image", image)
        end)
    }
    |> maybe_put(
      resp["meta"]["aggregations"]["categoryId"]["groups"] != nil,
      :categories,
      resp["meta"]["aggregations"]["categoryId"]["groups"]
    )
    |> maybe_put(
      resp["meta"]["totalAdCount"] != nil,
      :total_ads,
      resp["meta"]["totalAdCount"]
    )
  end

  defp get_resp(path) do
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

  # defp get_resp_with_auth(path) do
  #   :todo
  # end

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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
  defp maybe_put(map, false, _key, _value), do: map
  defp maybe_put(map, true, key, value), do: maybe_put(map, key, value)
end
