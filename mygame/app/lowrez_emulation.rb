# This is emulation code for lowrez
class LowrezGame
  attr_dr

  attr :w, :h

  def initialize(w:, h:)
    @w = w
    @h = h
    @lowrez_background_color = [255, 255, 255]
    @viewport_primitive = { x: 0, y: 0, w: 1280, h: 720, path: :lowrez }
  end

  def tick
  end

  def lowrez_outputs
    outputs[:lowrez].set w: @w,
                         h: @h,
                         background_color: @lowrez_background_color
    outputs[:lowrez].clear_before_render = true
    outputs[:lowrez]
  end

  def lowrez_mouse
    {
      x: inputs.mouse.x.idiv(zoom_x),
      y: inputs.mouse.y.idiv(zoom_y),
      w: 1,
      h: 1
    }
  end

  def zoom_x
    1280.fdiv(@w)
  end

  def zoom_y
    720.fdiv(@h)
  end

  def viewport_primitive
    @viewport_primitive
  end
end

module Main
  OUTPUT_BACKGROUND_COLOR = [0, 0, 0]

  def tick args
    @game ||= Game.new
    @game.args = args
    @game.tick
    args.outputs.background_color = OUTPUT_BACKGROUND_COLOR
    args.outputs.primitives << @game.viewport_primitive
    args.outputs.primitives << DR.framerate_diagnostics_primitives if @game.cheatmode?
  end

  def reset args
    @game = nil
  end
end
