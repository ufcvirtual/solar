class AccessControlController < ApplicationController

  # exibicao das imagens do usuario
  def photo
    unless current_user.nil?

      user = User.find_by_id(params[:id])

      # verifica se o usuario requisitado existe
      head(:bad_request) and return if user.nil?

      # path da foto do usuario. style => medium | small
      path = user.photo.path(params[:style])

      # bad request(404) caso o arquivo nao seja encontrado
      head(:bad_request) and return unless File.exist?(path)

      # envia a imagem
      send_file(path, { :disposition => 'inline', :content_type => 'image' }) # content-type espcífico pra imagem
    else
      redirect_to ({ :controller => 'user_sessions' }) # caso o usuario nao esteja autenticado
    end
  end

end
