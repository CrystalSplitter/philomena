defmodule Philomena.Comments.Query do
  alias Search.Parser

  def user_id_transform(_ctx, data) do
    case Integer.parse(data) do
      {int, _rest} ->
        {
          :ok,
          %{
            bool: %{
              must: [
                %{term: %{anonymous: false}},
                %{term: %{user_id: int}}
              ]
            }
          }
        }

      _err ->
        {:error, "Unknown `user_id' value."}
    end
  end

  def author_transform(_ctx, data) do
    {
      :ok,
      %{
        bool: %{
          must: [
            %{term: %{anonymous: false}},
            %{wildcard: %{author: data}}
          ]
        }
      }
    }
  end

  def user_my_transform(%{user: %{id: id}}, "comments"),
    do: {:ok, %{term: %{user_id: id}}}

  def user_my_transform(_ctx, _value),
    do: {:error, "Unknown `my' value."}

  int_fields         = ~W(id)
  date_fields        = ~W(created_at)
  literal_fields     = ~W(image_id)
  ngram_fields       = ~W(body)
  custom_fields      = ~W(author user_id)
  default_field      = "body"
  transforms         = %{
    "user_id" => &Philomena.Comments.Query.user_id_transform/2,
    "author" => &Philomena.Comments.Query.author_transform/2
  }
  aliases            = %{
    "created_at" => "posted_at",
  }

  user_custom        = custom_fields ++ ~W(my)
  user_transforms    = Map.merge(transforms, %{
    "my" => &Philomena.Comments.Query.user_my_transform/2
  })

  mod_literal_fields = literal_fields ++ ~W(fingerprint)
  mod_ip_fields      = ~W(ip)
  mod_bool_fields    = ~W(anonymous deleted)
  mod_aliases        =  Map.merge(aliases, %{
    "deleted" => "hidden_from_users"
  })


  @anonymous_parser Parser.parser(
    int_fields: int_fields,
    date_fields: date_fields,
    literal_fields: literal_fields,
    ngram_fields: ngram_fields,
    custom_fields: custom_fields,
    aliases: aliases,
    default_field: default_field
  )

  @user_parser Parser.parser(
    int_fields: int_fields,
    date_fields: date_fields,
    literal_fields: literal_fields,
    ngram_fields: ngram_fields,
    custom_fields: user_custom,
    transforms: user_transforms,
    aliases: aliases,
    default_field: default_field
  )

  @moderator_parser Parser.parser(
    int_fields: int_fields,
    date_fields: date_fields,
    literal_fields: mod_literal_fields,
    ip_fields: mod_ip_fields,
    ngram_fields: ngram_fields,
    bool_fields: mod_bool_fields,
    custom_fields: user_custom,
    transforms: user_transforms,
    aliases: mod_aliases,
    default_field: default_field
  )

  def parse_anonymous(context, query_string) do
    Parser.parse(@anonymous_parser, query_string, context)
  end

  def parse_user(context, query_string) do
    Parser.parse(@user_parser, query_string, context)
  end

  def parse_moderator(context, query_string) do
    Parser.parse(@moderator_parser, query_string, context)
  end

  def compile(user, query_string) do
    query_string = query_string || ""

    case user do
      nil ->
        parse_anonymous(%{user: nil}, query_string)

      %{role: role} when role in ~W(user assistant) ->
        parse_user(%{user: user}, query_string)

      %{role: role} when role in ~W(moderator admin) ->
        parse_moderator(%{user: user}, query_string)

      _ ->
        raise ArgumentError, "Unknown user role."
    end
  end
end
