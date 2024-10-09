defmodule Arrow.Shuttles.Shape do
  @moduledoc "schema for shuttle shapes for the db"
  use Ecto.Schema
  import Ecto.Changeset

  @type id :: integer
  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "shapes" do
    field :name, :string
    field :bucket, :string
    field :path, :string
    field :prefix, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shape, attrs) do
    shape
    |> cast(attrs, [:name, :path, :bucket, :prefix], empty_values: ["-S" | empty_values()])
    |> validate_required([:name, :path, :bucket, :prefix])
    |> unique_constraint(:name)
    |> validate_change(:name, fn :name, name ->
      if String.ends_with?(name, "-S") do
        []
      else
        [{:name, "must end with -S"}]
      end
    end)
  end

  def validate_and_enforce_name(attrs) do
    changeset =
      %__MODULE__{}
      |> cast(attrs, [:name])
      |> validate_required([:name])

    cond do
      not changeset.valid? ->
        {:error, changeset}

      String.ends_with?(attrs.name, "-S") ->
        {:ok, attrs}

      true ->
        {:ok, Map.put(attrs, :name, "#{attrs.name}-S")}
    end
  end
end
