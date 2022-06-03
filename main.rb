require 'gosu'
require './ui'


class GrapherWindow < Gosu::Window
    def initialize(window_width, window_height)
        super(window_width, window_height)
        self.caption = "Function Visualizer"
    end

    def needs_cursor?; true; end

    def update()

    end

    def draw()

    end

    def button_down(id)

    end
end

window = GrapherWindow.new(800, 600)
window.show()