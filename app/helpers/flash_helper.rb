module FlashHelper

  def show_flash
    if (not flash.empty?)
      msg = flash.map {|f| %{javascript:flash_message('#{f.last}', '#{f.first}')}}.first
      flash.clear
      return msg
    end
  end

end