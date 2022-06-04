require 'gosu'

module ZOrder
    BACKGROUND, MIDDLE, TOP = *0..2
end

module Ui
    class Button
        attr_accessor :left_x, :top_y, :rect_width, :rect_height, :width, :height, :bg_color, :font, :text, :padding, :margin

        def initialize(left_x, top_y, bg_color, font, text, padding, margin)
            @left_x = left_x
            @top_y = top_y
            @bg_color = bg_color
            @font = font
            @text = text
            @padding = padding
            @margin = margin

            #  Width and height of the button rectangle
            @height = @font.height + @padding * 2
            @width = @font.text_width(@text) + @padding * 2

            # @width = @rect_width + @margin * 2
            # @height = @rect_height + @margin * 2
        end
    end

    def self.draw_button(button)
        Gosu.draw_rect(
            button.left_x, button.top_y,
            button.width, button.height, button.bg_color
        )
        button.font.draw_text(
            button.text,
            button.left_x + button.padding, button.top_y + button.padding,
            ZOrder::MIDDLE, 1, 1, Gosu::Color::BLACK
        )
    end

    class TextBox
        attr_accessor :left_x, :top_y, :width, :height, :bg_color, :padding, :text_input, :font, :default_text

        def initialize(left_x, top_y, width, bg_color, font, text_input, padding, default_text='')
            @left_x = left_x
            @top_y = top_y
            @bg_color = bg_color
            @font = font
            @text_input = text_input
            @padding = padding
            @default_text = default_text

            #  Width and height of the rectangle
            @height = @font.height + @padding * 2
            @width = width

            # @width = @rect_width + @margin * 2
            # @height = @rect_height + @margin * 2
        end
    end

    def self.draw_text_box(text_box)
        Gosu.draw_rect(
            text_box.left_x, text_box.top_y,
            text_box.width, text_box.height,
            text_box.bg_color, ZOrder::BACKGROUND
        )

        display_text = ''

        if text_box.text_input.nil? or text_box.text_input.text == ''
            #  Display the default text if no input
            display_text = text_box.default_text
        else
            display_text = text_box.text_input.text
        end

        text_box.font.draw_text(
            display_text,
            text_box.left_x + text_box.padding,
            text_box.top_y + text_box.padding,
            ZOrder::MIDDLE, 1, 1, Gosu::Color::BLACK
        )
    end
end