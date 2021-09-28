defmodule Philomena.Commissions.Commission do
  use Ecto.Schema
  import Ecto.Changeset
  import Philomena.MarkdownWriter

  alias Philomena.Commissions.Item
  alias Philomena.Images.Image
  alias Philomena.Users.User

  schema "commissions" do
    belongs_to :user, User
    belongs_to :sheet_image, Image
    has_many :items, Item

    field :open, :boolean
    field :categories, {:array, :string}, default: []
    field :information, :string
    field :contact, :string
    field :will_create, :string
    field :will_not_create, :string
    field :information_md, :string
    field :contact_md, :string
    field :will_create_md, :string
    field :will_not_create_md, :string
    field :commission_items_count, :integer, default: 0

    timestamps(inserted_at: :created_at, type: :utc_datetime)
  end

  @doc false
  def changeset(commission, attrs) do
    commission
    |> cast(attrs, [
      :information,
      :contact,
      :will_create,
      :will_not_create,
      :open,
      :sheet_image_id,
      :categories
    ])
    |> drop_blank_categories()
    |> validate_required([:user_id, :information, :contact, :open])
    |> validate_length(:information, max: 1000, count: :bytes)
    |> validate_length(:contact, max: 1000, count: :bytes)
    |> validate_length(:will_create, max: 1000, count: :bytes)
    |> validate_length(:will_not_create, max: 1000, count: :bytes)
    |> validate_subset(:categories, Keyword.values(categories()))
    |> put_markdown(attrs, :information, :information_md)
    |> put_markdown(attrs, :contact, :contact_md)
    |> put_markdown(attrs, :will_create, :will_create_md)
    |> put_markdown(attrs, :will_not_create, :will_not_create_md)
  end

  defp drop_blank_categories(changeset) do
    categories =
      changeset
      |> get_field(:categories)
      |> Enum.filter(&(&1 not in [nil, ""]))

    change(changeset, categories: categories)
  end

  def categories do
    [
      Anthro: "Anthro",
      Comics: "Comics",
      "Fetish Art": "Fetish Art",
      NSFW: "NSFW",
      "Franchise Fan Art": "Franchise Fan Art",
      "Original Species": "Original Species",
      Requests: "Requests",
      Safe: "Safe",
      Shipping: "Shipping",
      "Violence and Gore": "Violence and Gore"
    ]
  end

  def types do
    [
      "Sketch",
      "Colored Sketch",
      "Inked",
      "Flat Color",
      "Vector",
      "Cel Shaded",
      "Fully Shaded",
      "Traditional",
      "Pixel Art",
      "Animation",
      "Crafted Item",
      "Sculpture",
      "Plushie",
      "Other"
    ]
  end
end
