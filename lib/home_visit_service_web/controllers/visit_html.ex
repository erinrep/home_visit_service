defmodule HomeVisitServiceWeb.VisitHTML do
  use HomeVisitServiceWeb, :html

  embed_templates "visit_html/*"

  @doc """
  Renders a visit form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def visit_form(assigns)
end
