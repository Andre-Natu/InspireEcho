defmodule CitacoesWeb.HomeLive do
  use CitacoesWeb, :live_view

  alias Citacoes.Posts
  alias Citacoes.Posts.Post

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
     O site está carregando ...
    """
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-3" >
      <div class="flex flex-col gap-2">
      <h1 class="text-2xl mx-auto">Home Page</h1>
      <p class="mx-auto"> Role para baixo para ver as citações </p>
      </div>
      <div class="flex flex-col gap-1">
      <.button type="button"  phx-click={show_modal("new-post-modal")}> Criar Citação </.button>
      </div>
      <div id="feed" phx-update="stream" class="flex flex-col gap-2">
        <div :for={{dorm_id, post} <- @streams.posts} id={dorm_id}
        class="mx-auto flex flex-col gap-2 p-4 border rounded">

          <img src={post.image_path} />
          <p><%= post.user.email %></p>
          <p><%= post.caption %></p>
        </div>
      </div>
    </div>
    <.modal id="new-post-modal">
      <.simple_form for={@form} phx-change="validate" phx-submit="save-post">
        <div class="flex flex-col gap-1">
        <img src={~p"/images/logo.svg"} width="36" class="mx-auto" />
         <h1 class="mx-auto text-2xl">Criar Citação</h1>
         <p class="mx-auto"> Digite aqui a sua citação que deseja postar. </p>
        </div>
        <div class="flex flex-col gap-1">
        <label class="text-sm font-semibold text-zinc-800">Enviar Imagem:</label>
        <.live_file_input upload={@uploads.image} class="phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3 text-sm font-semibold leading-6 text-white active:text-white/80 " required />
        <.input field={@form[:caption]} type="textarea" label="Citação" required />
        </div>
        <div class="flex flex-col gap-1">
        <.button type="submit" phx-disable-with="Saving ..."> Postar Citação </.button>
        </div>
      </.simple_form>
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Citacoes.PubSub, "posts")

      form =
        %Post{}
        |> Post.changeset(%{})
        |> to_form(as: "post")

      socket =
        socket
        |> assign(form: form, loading: false)
        |> allow_upload(:image, accept: ~w(.png .jpg), max_entries: 1)
        |> stream(:posts, Posts.list_posts())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-post", %{"post" => post_params}, socket) do
    %{current_user: user} = socket.assigns

    post_params
    |> Map.put("user_id", user.id)
    |> Map.put("image_path", List.first(consume_files(socket)))
    |> Posts.save()
    |> case do
        {:ok, post} ->
            socket =
              socket
              |> put_flash(:info, "Citação criada com sucesso!")
              |> push_navigate(to: ~p"/home")

          Phoenix.PubSub.broadcast(Citacoes.PubSub, "posts", {:new, Map.put(post, :user, user)})

          {:noreply, socket}
        {:error, _changeset} ->
          {:noreply, socket}
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new, post}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{post.user.email} acabou de postar uma citação!")
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end

  defp consume_files(socket) do
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      dest = Path.join([:code.priv_dir(:citacoes), "static", "uploads", Path.basename(path)])
      File.cp!(path, dest)

      {:postpone, ~p"/uploads/#{Path.basename(dest)}"}
    end)
  end
end
